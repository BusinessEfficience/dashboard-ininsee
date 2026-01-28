-- =============================================================================
-- Supabase Database Setup Script
-- =============================================================================
-- Instructions:
-- 1. Go to https://supabase.com and create a new project (or use existing)
-- 2. Navigate to SQL Editor in the Supabase dashboard
-- 3. Copy and paste this entire script
-- 4. Click "Run" to execute all commands
-- 5. Verify tables created: Settings → Tables → logs, metrics
-- 6. Verify RLS: Settings → API → Row Level Security
-- =============================================================================
-- Date: 2026-01-28
-- Purpose: Secure INSEE dashboard with Supabase integration
-- =============================================================================

-- Enable UUID extension for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- Drop existing tables (if re-running script)
-- =============================================================================
DROP TABLE IF EXISTS logs CASCADE;
DROP TABLE IF EXISTS metrics CASCADE;

-- =============================================================================
-- Create logs table with enhanced schema
-- =============================================================================
CREATE TABLE logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    log_date date NOT NULL,
    log_time time NOT NULL,
    entry_id text NOT NULL,
    score numeric NOT NULL CHECK (score >= 0 AND score <= 100),
    user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    ip_address inet,
    user_agent text,
    deleted_at timestamptz
);

-- =============================================================================
-- Create indexes for performance optimization
-- =============================================================================
CREATE INDEX idx_logs_created_at ON logs(created_at DESC);
CREATE INDEX idx_logs_user_id ON logs(user_id);
CREATE INDEX idx_logs_date ON logs(log_date DESC);
CREATE INDEX idx_logs_score ON logs(score DESC);

-- =============================================================================
-- Enable Row Level Security (RLS) on logs table
-- =============================================================================
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- RLS Policies for logs table
-- =============================================================================
-- Allow public read access
CREATE POLICY "Allow public read" ON logs FOR SELECT USING (true);

-- Allow public insert access
CREATE POLICY "Allow public insert" ON logs FOR INSERT WITH CHECK (true);

-- Allow public delete access
CREATE POLICY "Allow public delete" ON logs FOR DELETE USING (true);

-- Allow public update access
CREATE POLICY "Allow public update" ON logs FOR UPDATE USING (true);

-- =============================================================================
-- Create metrics table for dashboard aggregations
-- =============================================================================
CREATE TABLE metrics (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    weekly_entries integer DEFAULT 0,
    weekly_avg_score numeric DEFAULT 0,
    weekly_start_date date,
    daily_entries integer DEFAULT 0,
    daily_avg_score numeric DEFAULT 0,
    daily_date date,
    total_entries bigint DEFAULT 0,
    overall_avg_score numeric DEFAULT 0,
    last_log_id uuid
);

-- =============================================================================
-- Initialize singleton metrics record
-- =============================================================================
INSERT INTO metrics (id, weekly_start_date, daily_date)
VALUES ('00000000-0000-0000-0000-000000000001', CURRENT_DATE, CURRENT_DATE)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- Enable RLS on metrics table
-- =============================================================================
ALTER TABLE metrics ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Allow public read metrics" ON metrics FOR SELECT USING (true);

-- Service role only (no public access)
CREATE POLICY "Service role only metrics" ON metrics FOR ALL USING (false) WITH CHECK (false);

-- =============================================================================
-- Create auto-update function for metrics
-- =============================================================================
DROP FUNCTION IF EXISTS update_metrics();

CREATE OR REPLACE FUNCTION update_metrics()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE metrics SET
        weekly_entries = (SELECT COUNT(*) FROM logs WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
        weekly_avg_score = (SELECT AVG(score) FROM logs WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
        weekly_start_date = DATE_TRUNC('week', CURRENT_DATE),
        updated_at = now()
        WHERE id = '00000000-0000-0000-0000-000000000001';
    
    UPDATE metrics SET
        daily_entries = (SELECT COUNT(*) FROM logs WHERE DATE(created_at) = CURRENT_DATE),
        daily_avg_score = (SELECT AVG(score) FROM logs WHERE DATE(created_at) = CURRENT_DATE),
        daily_date = CURRENT_DATE,
        updated_at = now()
        WHERE id = '00000000-0000-0000-0000-000000000001';
    
    UPDATE metrics SET
        total_entries = (SELECT COUNT(*) FROM logs),
        overall_avg_score = (SELECT AVG(score) FROM logs),
        last_log_id = NEW.id,
        updated_at = now()
        WHERE id = '00000000-0000-0000-0000-000000000001';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- Create trigger for auto-update on log insert
-- =============================================================================
DROP TRIGGER IF EXISTS on_log_insert ON logs;

CREATE TRIGGER on_log_insert
    AFTER INSERT ON logs
    FOR EACH ROW
    EXECUTE FUNCTION update_metrics();

-- =============================================================================
-- Verification queries (run these to check setup)
-- =============================================================================
-- SELECT * FROM logs LIMIT 5;
-- SELECT * FROM metrics;
-- SELECT * FROM pg_policies WHERE tablename = 'logs';
