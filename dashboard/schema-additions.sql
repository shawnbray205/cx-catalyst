-- =====================================================
-- Token Usage & Dashboard Metrics Schema Additions
-- CX-Catalyst System
-- =====================================================

-- -----------------------------------------------------
-- Token Usage Tracking
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS token_usage (
    usage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_name VARCHAR(100) NOT NULL,
    workflow_execution_id VARCHAR(255),
    case_id UUID REFERENCES cases(case_id),
    provider VARCHAR(50) NOT NULL, -- 'anthropic', 'openai'
    model VARCHAR(100) NOT NULL, -- 'claude-sonnet-4', 'text-embedding-3-large'
    operation_type VARCHAR(50), -- 'triage', 'solution', 'embedding', 'analysis'
    input_tokens INTEGER NOT NULL DEFAULT 0,
    output_tokens INTEGER NOT NULL DEFAULT 0,
    total_tokens INTEGER GENERATED ALWAYS AS (input_tokens + output_tokens) STORED,
    cost_usd DECIMAL(10, 6), -- Calculated cost
    latency_ms INTEGER, -- Response time
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    recorded_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_token_usage_workflow ON token_usage(workflow_name);
CREATE INDEX idx_token_usage_provider ON token_usage(provider);
CREATE INDEX idx_token_usage_recorded_at ON token_usage(recorded_at DESC);
CREATE INDEX idx_token_usage_case ON token_usage(case_id);

-- -----------------------------------------------------
-- Token Budget Configuration
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS token_budgets (
    budget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_name VARCHAR(100) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    budget_type VARCHAR(20) NOT NULL, -- 'monthly', 'daily'
    token_limit BIGINT NOT NULL,
    cost_limit_usd DECIMAL(10, 2),
    warning_threshold DECIMAL(3, 2) DEFAULT 0.80, -- Alert at 80%
    critical_threshold DECIMAL(3, 2) DEFAULT 0.95, -- Critical at 95%
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_token_budgets_active ON token_budgets(is_active, period_start, period_end);

-- Insert default budgets
INSERT INTO token_budgets (budget_name, provider, budget_type, token_limit, cost_limit_usd, period_start, period_end)
VALUES
    ('Anthropic Monthly', 'anthropic', 'monthly', 10000000, 3000.00, DATE_TRUNC('month', CURRENT_DATE), DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'),
    ('OpenAI Monthly', 'openai', 'monthly', 5000000, 500.00, DATE_TRUNC('month', CURRENT_DATE), DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'),
    ('Anthropic Daily', 'anthropic', 'daily', 500000, 150.00, CURRENT_DATE, CURRENT_DATE),
    ('OpenAI Daily', 'openai', 'daily', 250000, 25.00, CURRENT_DATE, CURRENT_DATE);

-- -----------------------------------------------------
-- Daily Metrics Snapshots (for historical tracking)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS daily_metrics (
    metric_date DATE PRIMARY KEY,

    -- Case Metrics
    total_cases INTEGER DEFAULT 0,
    resolved_cases INTEGER DEFAULT 0,
    escalated_cases INTEGER DEFAULT 0,
    self_service_cases INTEGER DEFAULT 0,
    collaborative_cases INTEGER DEFAULT 0,

    -- Resolution Metrics
    avg_resolution_time_minutes DECIMAL(10, 2),
    median_resolution_time_minutes DECIMAL(10, 2),
    first_contact_resolution_count INTEGER DEFAULT 0,

    -- Customer Satisfaction
    avg_satisfaction_score DECIMAL(3, 2),
    satisfaction_responses INTEGER DEFAULT 0,

    -- AI Performance
    avg_confidence_score DECIMAL(3, 2),
    ai_approvals INTEGER DEFAULT 0,
    ai_edits INTEGER DEFAULT 0,
    ai_rejections INTEGER DEFAULT 0,

    -- Token Usage
    anthropic_input_tokens BIGINT DEFAULT 0,
    anthropic_output_tokens BIGINT DEFAULT 0,
    anthropic_cost_usd DECIMAL(10, 2) DEFAULT 0,
    openai_input_tokens BIGINT DEFAULT 0,
    openai_output_tokens BIGINT DEFAULT 0,
    openai_cost_usd DECIMAL(10, 2) DEFAULT 0,

    -- Efficiency
    estimated_time_saved_minutes INTEGER DEFAULT 0,
    estimated_cost_saved_usd DECIMAL(10, 2) DEFAULT 0,

    -- Workflow Health
    workflow_executions INTEGER DEFAULT 0,
    workflow_failures INTEGER DEFAULT 0,
    avg_workflow_duration_ms INTEGER,

    created_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- -----------------------------------------------------
-- Pricing Configuration (for cost calculations)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS api_pricing (
    pricing_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    input_price_per_million DECIMAL(10, 4) NOT NULL, -- USD per 1M tokens
    output_price_per_million DECIMAL(10, 4) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_current BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_api_pricing_current ON api_pricing(provider, model, is_current);

-- Insert current pricing (January 2026 rates - update as needed)
INSERT INTO api_pricing (provider, model, input_price_per_million, output_price_per_million, effective_from)
VALUES
    ('anthropic', 'claude-sonnet-4', 3.00, 15.00, '2026-01-01'),
    ('anthropic', 'claude-haiku-3', 0.25, 1.25, '2026-01-01'),
    ('openai', 'gpt-4-turbo', 10.00, 30.00, '2026-01-01'),
    ('openai', 'gpt-4o', 5.00, 15.00, '2026-01-01'),
    ('openai', 'text-embedding-3-large', 0.13, 0.00, '2026-01-01'),
    ('openai', 'text-embedding-3-small', 0.02, 0.00, '2026-01-01');

-- -----------------------------------------------------
-- Baseline Configuration (for savings calculations)
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS baseline_config (
    config_key VARCHAR(100) PRIMARY KEY,
    config_value DECIMAL(10, 2) NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert baseline values for ROI calculations
INSERT INTO baseline_config (config_key, config_value, description)
VALUES
    ('manual_cost_per_case', 20.00, 'Average cost for fully manual case handling'),
    ('manual_avg_resolution_minutes', 45, 'Average resolution time without AI'),
    ('hourly_support_cost', 35.00, 'Fully-loaded hourly cost of support staff'),
    ('self_service_cost_per_case', 2.00, 'Cost for AI-automated case resolution'),
    ('collaborative_cost_per_case', 10.00, 'Cost for human-reviewed AI resolution'),
    ('escalated_cost_per_case', 25.00, 'Cost for fully escalated cases'),
    ('target_self_service_rate', 0.85, 'Target self-service resolution rate'),
    ('target_csat_score', 4.5, 'Target customer satisfaction score')
ON CONFLICT (config_key) DO NOTHING;

-- -----------------------------------------------------
-- KB Performance Tracking
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS kb_article_performance (
    performance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID REFERENCES kb_articles(article_id),
    metric_date DATE NOT NULL,
    retrievals INTEGER DEFAULT 0,
    successful_resolutions INTEGER DEFAULT 0,
    partial_resolutions INTEGER DEFAULT 0,
    failed_resolutions INTEGER DEFAULT 0,
    avg_relevance_score DECIMAL(3, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(article_id, metric_date)
);

CREATE INDEX idx_kb_perf_date ON kb_article_performance(metric_date DESC);

-- -----------------------------------------------------
-- Improvement Tracking
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS improvement_opportunities (
    opportunity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    opportunity_type VARCHAR(50) NOT NULL, -- 'kb_gap', 'escalation_pattern', 'low_confidence', 'recurring_issue'
    title VARCHAR(500) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    frequency INTEGER DEFAULT 1,
    impact_score DECIMAL(3, 2), -- 0-1 impact rating
    status VARCHAR(50) DEFAULT 'identified', -- 'identified', 'in_progress', 'resolved', 'dismissed'
    resolution_notes TEXT,
    first_detected DATE DEFAULT CURRENT_DATE,
    last_detected DATE DEFAULT CURRENT_DATE,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_improvement_type ON improvement_opportunities(opportunity_type, status);
CREATE INDEX idx_improvement_impact ON improvement_opportunities(impact_score DESC);
