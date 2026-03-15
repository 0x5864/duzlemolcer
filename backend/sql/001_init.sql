CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  angle_x DOUBLE PRECISION NOT NULL CHECK (angle_x BETWEEN -180 AND 180),
  angle_y DOUBLE PRECISION NOT NULL CHECK (angle_y BETWEEN -180 AND 180),
  mode TEXT NOT NULL CHECK (mode IN ('level', 'plumb')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_measurements_created_at
  ON measurements (created_at DESC);
