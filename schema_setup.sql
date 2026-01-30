-- FINAL COMPREHENSIVE FIX SCRIPT
-- Run this in your Supabase SQL Editor to reset permissions and policies.

-- 1. Enable RLS (Safe)
alter table public.vendors enable row level security;

-- 2. EXPLICIT GRANTS (Fixes "Permission denied")
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on table public.vendors to postgres, anon, authenticated, service_role;

-- 3. AGGRESSIVE CLEANUP (Drop ALL potential old policies by name)
drop policy if exists "Vendors can view own profile" on public.vendors;
drop policy if exists "Vendors can insert own profile" on public.vendors;
drop policy if exists "Vendors can update own profile" on public.vendors;
drop policy if exists "Admin can view all vendors" on public.vendors;
drop policy if exists "Admin can update all vendors" on public.vendors;
-- Drop potentially renamed loose policies if any (Add common variations if needed)

-- 4. CREATE ROBUST POLICIES

-- View Own Profile
create policy "Vendors can view own profile" 
on public.vendors for select 
using (auth.uid() = id);

-- Insert Own Profile
create policy "Vendors can insert own profile" 
on public.vendors for insert 
with check (auth.uid() = id);

-- Update Own Profile (UPSERT friendly)
create policy "Vendors can update own profile" 
on public.vendors for update 
using (auth.uid() = id)
with check (auth.uid() = id);

-- ADMIN VIEW (Uses JWT Metadata, avoids accessing auth.users table)
create policy "Admin can view all vendors" 
on public.vendors for select 
using ((auth.jwt() ->> 'email') = 'admin@test.com');

-- ADMIN UPDATE
create policy "Admin can update all vendors" 
on public.vendors for update 
using ((auth.jwt() ->> 'email') = 'admin@test.com');

-- 5. STORAGE BUCKET
insert into storage.buckets (id, name, public) 
values ('vendor_docs', 'vendor_docs', true)
on conflict (id) do nothing;

-- 6. STORAGE POLICIES
drop policy if exists "Vendors can upload own documents" on storage.objects;
drop policy if exists "Vendors can view own documents" on storage.objects;
drop policy if exists "Admin can view all documents" on storage.objects;

-- Upload: Must be in folder matching User ID
create policy "Vendors can upload own documents" 
on storage.objects for insert 
with check (
  bucket_id = 'vendor_docs' and 
  auth.uid() = (storage.foldername(name))[1]::uuid
);

-- View: Must be in folder matching User ID
create policy "Vendors can view own documents" 
on storage.objects for select 
using (
  bucket_id = 'vendor_docs' and 
  auth.uid() = (storage.foldername(name))[1]::uuid
);

-- Admin View: Uses JWT
create policy "Admin can view all documents"
on storage.objects for select
using (
  bucket_id = 'vendor_docs' and 
  (auth.jwt() ->> 'email') = 'admin@test.com'
);
