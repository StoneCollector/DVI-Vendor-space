import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = "dreamventz2026";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

function base64url(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(): Promise<string> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not set");
  const sa = JSON.parse(raw);

  const header = base64url(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" }))
  );
  const now = Math.floor(Date.now() / 1000);
  const payload = base64url(
    new TextEncoder().encode(JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }))
  );

  const signingInput = `${header}.${payload}`;
  const pemBody = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\n/g, "");

  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8", keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false, ["sign"]
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", cryptoKey,
    new TextEncoder().encode(signingInput)
  );
  const jwt = `${signingInput}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) throw new Error(`Token error: ${await res.text()}`);
  return (await res.json()).access_token;
}

async function sendFcmNotification(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channel_id: "booking_channel",   // ✅ matches vendor app channel
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          apns: { payload: { aps: { sound: "default", badge: 1 } } },
        },
      }),
    }
  );
  if (!res.ok) {
    console.error(`FCM failed: ${await res.text()}`);
    return false;
  }
  return true;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { vendor_id, order_id, amount, payment_id, items } = await req.json();

    if (!vendor_id || !order_id || !amount) {
      return new Response(
        JSON.stringify({ success: false, error: "vendor_id, order_id and amount are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // ✅ Query 'vendors' table — confirmed from your schema screenshot
    const { data: vendor, error: vendorError } = await supabase
      .from("vendors")
      .select("fcm_token, full_name")
      .eq("id", vendor_id)
      .single();

    if (vendorError || !vendor) {
      console.error("Vendor not found:", vendorError);
      return new Response(
        JSON.stringify({ success: false, error: "Vendor not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { fcm_token } = vendor;

    if (!fcm_token) {
      console.warn(`Vendor ${vendor_id} has no FCM token — skipped`);
      return new Response(
        JSON.stringify({ success: true, sent: false, reason: "No FCM token" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build item summary e.g. "Photography ×2, Decor ×1"
    const itemSummary = Array.isArray(items) && items.length > 0
      ? items.map((i: { name: string; quantity: number }) =>
          `${i.name} ×${i.quantity}`
        ).join(", ")
      : "Services booked";

    const formattedAmount = `₹${Number(amount).toLocaleString("en-IN")}`;

    const accessToken = await getAccessToken();
    const sent = await sendFcmNotification(
      accessToken,
      fcm_token,
      "🎉 New Order Received!",
      `${formattedAmount} • ${itemSummary}`,
      {
        type: "new_order",
        order_id: order_id.toString(),
        vendor_id: vendor_id.toString(),
        amount: amount.toString(),
        payment_id: payment_id ?? "",
      }
    );

    console.log(`✅ Vendor ${vendor_id} notified: ${sent}`);

    return new Response(
      JSON.stringify({ success: true, sent }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("notify-vendor-new-order error:", err);
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});