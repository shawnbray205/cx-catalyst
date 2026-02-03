-- =====================================================
-- Batch Jobs Tracking Schema
-- CX-Catalyst System — DEV-47
-- =====================================================
-- Tracks OpenAI and Anthropic batch API jobs submitted
-- by WF3 and WF5. The Batch Job Poller reads pending
-- rows, polls the provider API, and PUTs results to
-- resume_url to wake up the parent workflow.
-- =====================================================

CREATE TABLE IF NOT EXISTS batch_jobs (
    batch_job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Provider batch identifier (e.g. batch_abc123 from OpenAI)
    batch_id VARCHAR(255) NOT NULL,

    -- 'openai' or 'anthropic'
    provider VARCHAR(20) NOT NULL,

    -- Which workflow submitted this job
    workflow_name VARCHAR(100) NOT NULL,       -- 'WF3', 'WF5'

    -- Stage within the workflow
    workflow_stage VARCHAR(50) NOT NULL,        -- 'anomaly_analysis', 'pattern_analysis', 'article_generation'

    -- Execution ID of the parent workflow run
    parent_run_id VARCHAR(255) NOT NULL,

    -- Lifecycle status
    status VARCHAR(20) NOT NULL DEFAULT 'submitted',
    -- Values: 'submitted', 'in_progress', 'completed', 'failed', 'expired', 'cancelled'

    -- OpenAI-specific: the uploaded JSONL file ID
    input_file_id VARCHAR(255),

    -- Provider-returned URL to download results
    results_url TEXT,

    -- n8n $execution.resumeUrl — Poller PUTs here to wake parent
    resume_url TEXT NOT NULL,

    -- Arbitrary context passed through to the resumed workflow
    context_data JSONB DEFAULT '{}',

    -- Timestamps
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Error details on failure
    error_message TEXT,

    -- Optional: raw result payload for debugging / replay
    result_payload JSONB
);

-- ----- Indexes -----

-- Poller queries pending/in_progress jobs
CREATE INDEX idx_batch_jobs_status
    ON batch_jobs(status)
    WHERE status IN ('submitted', 'in_progress');

-- Filter by provider + status for provider-specific polling
CREATE INDEX idx_batch_jobs_provider_status
    ON batch_jobs(provider, status);

-- Look up by provider batch ID (unique per provider)
CREATE UNIQUE INDEX idx_batch_jobs_batch_id
    ON batch_jobs(batch_id);

-- Correlate back to parent workflow executions
CREATE INDEX idx_batch_jobs_parent_run
    ON batch_jobs(parent_run_id);

-- Cleanup / reporting by submission date
CREATE INDEX idx_batch_jobs_submitted_at
    ON batch_jobs(submitted_at DESC);
