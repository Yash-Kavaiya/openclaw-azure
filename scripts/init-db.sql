-- OpenClaw Database Initialization
-- Run on fresh PostgreSQL instance

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- For full-text search
CREATE EXTENSION IF NOT EXISTS btree_gin; -- For GIN indexes

-- Performance indexes (tables created by SQLAlchemy/Alembic)
-- These are created after initial migration

-- Full text search index on cases (run after initial migration)
-- CREATE INDEX CONCURRENTLY idx_cases_title_fts ON cases USING gin(to_tsvector('english', title));
-- CREATE INDEX CONCURRENTLY idx_cases_content_fts ON cases USING gin(to_tsvector('english', coalesce(content, '')));

-- Set timezone
SET timezone = 'UTC';
