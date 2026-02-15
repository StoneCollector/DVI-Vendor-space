-- DreamVentz Vendor App - Database Migration
-- Role-Based Access Control, Venue Capacity, and Issue Reporting

-- ============================================================
-- 1. Add role column to vendors table
-- ============================================================
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='vendors' AND column_name='role') THEN
    ALTER TABLE vendors ADD COLUMN role TEXT DEFAULT 'venue_distributor';
  END IF;
END $$;

-- Add role constraint
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vendors_role_check') THEN
    ALTER TABLE vendors ADD CONSTRAINT vendors_role_check 
      CHECK (role IN ('admin', 'venue_distributor', 'vendor_distributor', 'venue_vendor_distributor'));
  END IF;
END $$;

-- ============================================================
-- 2. Add capacity to venues table
-- ============================================================
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='venues' AND column_name='capacity') THEN
    ALTER TABLE venues ADD COLUMN capacity INTEGER;
  END IF;
END $$;

-- ============================================================
-- 3. Create reported_issues table
-- ============================================================
CREATE TABLE IF NOT EXISTS reported_issues (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID REFERENCES vendors(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 4. Set up RLS policies for reported_issues
-- ============================================================

-- Enable RLS
ALTER TABLE reported_issues ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running script)
DROP POLICY IF EXISTS "Vendors can create issues" ON reported_issues;
DROP POLICY IF EXISTS "Vendors can view own issues" ON reported_issues;
DROP POLICY IF EXISTS "Admins can view all issues" ON reported_issues;
DROP POLICY IF EXISTS "Admins can update all issues" ON reported_issues;

-- Vendors can insert their own issues
CREATE POLICY "Vendors can create issues"
  ON reported_issues FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

-- Vendors can view their own issues
CREATE POLICY "Vendors can view own issues"
  ON reported_issues FOR SELECT
  USING (auth.uid() = reporter_id);

-- Admins can view all issues
CREATE POLICY "Admins can view all issues"
  ON reported_issues FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vendors 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update all issues
CREATE POLICY "Admins can update all issues"
  ON reported_issues FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM vendors 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- 5. Update existing admin account (MANUAL STEP)
-- ============================================================
-- IMPORTANT: Run this after the migration
-- Replace 'YOUR_ADMIN_USER_ID' with the actual admin user ID

-- UPDATE vendors 
-- SET role = 'admin' 
-- WHERE email = 'admin@test.com';

-- ============================================================
-- 6. Create index for performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_reported_issues_reporter_id ON reported_issues(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reported_issues_status ON reported_issues(status);
CREATE INDEX IF NOT EXISTS idx_vendors_role ON vendors(role);

-- ============================================================
-- Migration Complete
-- ============================================================
-- Next steps:
-- 1. Update the admin user email with: UPDATE vendors SET role = 'admin' WHERE email = 'admin@test.com';
-- 2. Test the migration by checking:
--    - SELECT * FROM vendors LIMIT 1; (should see 'role' column)
--    - SELECT * FROM venues LIMIT 1; (should see 'capacity' column)
--    - SELECT * FROM reported_issues; (table should exist)
--    - \d reported_issues (check RLS policies exist)
