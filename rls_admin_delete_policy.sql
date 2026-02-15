-- Add RLS DELETE policy for admins to delete vendors
-- Run this in your Supabase SQL Editor

-- ============================================================
-- Allow admins to delete vendors
-- ============================================================

-- Drop existing policy if it exists (for re-running script)
DROP POLICY IF EXISTS "Admins can delete vendors" ON vendors;

-- Create DELETE policy for admins
CREATE POLICY "Admins can delete vendors"
  ON vendors FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM vendors 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- Optional: Add other admin management policies if needed
-- ============================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can view all vendors" ON vendors;
DROP POLICY IF EXISTS "Admins can update all vendors" ON vendors;

-- Admins can view all vendors
CREATE POLICY "Admins can view all vendors"
  ON vendors FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vendors 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update all vendors (for role changes)
CREATE POLICY "Admins can update all vendors"
  ON vendors FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM vendors 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- Verification
-- ============================================================
-- After running this, verify the policies exist:
-- SELECT * FROM pg_policies WHERE tablename = 'vendors';
