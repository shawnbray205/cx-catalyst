-- =====================================================
-- Grafana Dashboard Views
-- Pre-computed metrics for efficient dashboard queries
-- =====================================================

-- -----------------------------------------------------
-- VIEW: Current Period Token Usage Summary
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_token_usage_summary AS
SELECT
    DATE(recorded_at) as usage_date,
    provider,
    workflow_name,
    model,
    operation_type,
    COUNT(*) as request_count,
    SUM(input_tokens) as total_input_tokens,
    SUM(output_tokens) as total_output_tokens,
    SUM(total_tokens) as total_tokens,
    SUM(cost_usd) as total_cost_usd,
    AVG(latency_ms) as avg_latency_ms,
    COUNT(CASE WHEN success THEN 1 END) as success_count,
    COUNT(CASE WHEN NOT success THEN 1 END) as error_count
FROM token_usage
WHERE recorded_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(recorded_at), provider, workflow_name, model, operation_type;

-- -----------------------------------------------------
-- VIEW: Budget Utilization
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_budget_utilization AS
SELECT
    b.budget_id,
    b.budget_name,
    b.provider,
    b.budget_type,
    b.token_limit,
    b.cost_limit_usd,
    b.warning_threshold,
    b.critical_threshold,
    b.period_start,
    b.period_end,
    COALESCE(u.tokens_used, 0) as tokens_used,
    COALESCE(u.cost_used, 0) as cost_used,
    ROUND(COALESCE(u.tokens_used, 0)::numeric / b.token_limit * 100, 2) as token_utilization_pct,
    ROUND(COALESCE(u.cost_used, 0) / NULLIF(b.cost_limit_usd, 0) * 100, 2) as cost_utilization_pct,
    CASE
        WHEN COALESCE(u.tokens_used, 0)::numeric / b.token_limit >= b.critical_threshold THEN 'critical'
        WHEN COALESCE(u.tokens_used, 0)::numeric / b.token_limit >= b.warning_threshold THEN 'warning'
        ELSE 'normal'
    END as status,
    -- Days remaining in period
    (b.period_end - CURRENT_DATE) as days_remaining,
    -- Projected exhaustion
    CASE
        WHEN COALESCE(u.tokens_used, 0) > 0 AND (CURRENT_DATE - b.period_start) > 0 THEN
            b.period_start + (
                (b.token_limit::numeric / (u.tokens_used::numeric / GREATEST((CURRENT_DATE - b.period_start), 1)))
            )::integer
        ELSE NULL
    END as projected_exhaustion_date
FROM token_budgets b
LEFT JOIN (
    SELECT
        provider,
        SUM(total_tokens) as tokens_used,
        SUM(cost_usd) as cost_used
    FROM token_usage
    WHERE recorded_at >= (SELECT MIN(period_start) FROM token_budgets WHERE is_active)
    GROUP BY provider
) u ON b.provider = u.provider
WHERE b.is_active = TRUE;

-- -----------------------------------------------------
-- VIEW: Case Resolution Metrics (Real-time)
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_case_metrics_realtime AS
SELECT
    -- Time buckets
    DATE(created_at) as case_date,
    EXTRACT(HOUR FROM created_at) as case_hour,

    -- Volume
    COUNT(*) as total_cases,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
    COUNT(CASE WHEN status = 'escalated' OR escalated = TRUE THEN 1 END) as escalated,
    COUNT(CASE WHEN status IN ('new', 'triaged', 'in_progress', 'pending_review') THEN 1 END) as open,

    -- Resolution paths
    COUNT(CASE WHEN resolution_type = 'self-service-automated' THEN 1 END) as self_service_auto,
    COUNT(CASE WHEN resolution_type = 'self-service-manual' THEN 1 END) as self_service_manual,
    COUNT(CASE WHEN resolution_type = 'collaborative' THEN 1 END) as collaborative,
    COUNT(CASE WHEN resolution_type = 'escalated' THEN 1 END) as fully_escalated,

    -- Categories
    category,
    priority,

    -- Metrics
    AVG(confidence_score) as avg_confidence,
    AVG(resolution_time_minutes) FILTER (WHERE resolved_at IS NOT NULL) as avg_resolution_time,
    AVG(satisfaction_score) FILTER (WHERE satisfaction_score IS NOT NULL) as avg_satisfaction,

    -- Counts
    COUNT(satisfaction_score) as satisfaction_responses

FROM cases
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at), EXTRACT(HOUR FROM created_at), category, priority;

-- -----------------------------------------------------
-- VIEW: Daily KPI Summary
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_daily_kpi AS
WITH daily_cases AS (
    SELECT
        DATE(created_at) as metric_date,
        COUNT(*) as total_cases,
        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_cases,
        COUNT(CASE WHEN escalated = TRUE THEN 1 END) as escalated_cases,
        COUNT(CASE WHEN resolution_type LIKE 'self-service%' THEN 1 END) as self_service_cases,
        COUNT(CASE WHEN resolution_type = 'collaborative' THEN 1 END) as collaborative_cases,
        AVG(resolution_time_minutes) FILTER (WHERE resolved_at IS NOT NULL) as avg_resolution_time,
        AVG(satisfaction_score) FILTER (WHERE satisfaction_score IS NOT NULL) as avg_satisfaction,
        COUNT(satisfaction_score) as satisfaction_count,
        AVG(confidence_score) as avg_confidence
    FROM cases
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(created_at)
),
daily_tokens AS (
    SELECT
        DATE(recorded_at) as metric_date,
        SUM(CASE WHEN provider = 'anthropic' THEN total_tokens ELSE 0 END) as anthropic_tokens,
        SUM(CASE WHEN provider = 'anthropic' THEN cost_usd ELSE 0 END) as anthropic_cost,
        SUM(CASE WHEN provider = 'openai' THEN total_tokens ELSE 0 END) as openai_tokens,
        SUM(CASE WHEN provider = 'openai' THEN cost_usd ELSE 0 END) as openai_cost
    FROM token_usage
    WHERE recorded_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(recorded_at)
),
daily_feedback AS (
    SELECT
        DATE(created_at) as metric_date,
        COUNT(CASE WHEN feedback_type = 'approval' THEN 1 END) as approvals,
        COUNT(CASE WHEN feedback_type = 'correction' THEN 1 END) as edits,
        COUNT(CASE WHEN feedback_type = 'rejection' THEN 1 END) as rejections
    FROM agent_feedback
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(created_at)
),
baseline AS (
    SELECT
        (SELECT config_value FROM baseline_config WHERE config_key = 'manual_cost_per_case') as manual_cost,
        (SELECT config_value FROM baseline_config WHERE config_key = 'manual_avg_resolution_minutes') as manual_time,
        (SELECT config_value FROM baseline_config WHERE config_key = 'self_service_cost_per_case') as self_service_cost,
        (SELECT config_value FROM baseline_config WHERE config_key = 'collaborative_cost_per_case') as collab_cost,
        (SELECT config_value FROM baseline_config WHERE config_key = 'escalated_cost_per_case') as escalated_cost
)
SELECT
    dc.metric_date,

    -- Case Metrics
    dc.total_cases,
    dc.resolved_cases,
    dc.escalated_cases,
    dc.self_service_cases,
    dc.collaborative_cases,
    ROUND(dc.resolved_cases::numeric / NULLIF(dc.total_cases, 0) * 100, 1) as resolution_rate,
    ROUND(dc.self_service_cases::numeric / NULLIF(dc.total_cases, 0) * 100, 1) as self_service_rate,

    -- Resolution Quality
    ROUND(dc.avg_resolution_time, 1) as avg_resolution_time_min,
    ROUND(dc.avg_satisfaction, 2) as avg_satisfaction_score,
    dc.satisfaction_count as satisfaction_responses,
    ROUND(dc.avg_confidence, 2) as avg_ai_confidence,

    -- AI Performance
    COALESCE(df.approvals, 0) as ai_approvals,
    COALESCE(df.edits, 0) as ai_edits,
    COALESCE(df.rejections, 0) as ai_rejections,
    ROUND(
        COALESCE(df.approvals, 0)::numeric /
        NULLIF(COALESCE(df.approvals, 0) + COALESCE(df.edits, 0) + COALESCE(df.rejections, 0), 0) * 100
    , 1) as ai_approval_rate,

    -- Token Usage
    COALESCE(dt.anthropic_tokens, 0) as anthropic_tokens,
    COALESCE(dt.anthropic_cost, 0) as anthropic_cost_usd,
    COALESCE(dt.openai_tokens, 0) as openai_tokens,
    COALESCE(dt.openai_cost, 0) as openai_cost_usd,
    COALESCE(dt.anthropic_cost, 0) + COALESCE(dt.openai_cost, 0) as total_ai_cost_usd,

    -- Savings Calculations
    ROUND(
        (dc.total_cases * b.manual_cost) -
        (dc.self_service_cases * b.self_service_cost +
         dc.collaborative_cases * b.collab_cost +
         dc.escalated_cases * b.escalated_cost +
         COALESCE(dt.anthropic_cost, 0) + COALESCE(dt.openai_cost, 0))
    , 2) as cost_saved_usd,

    ROUND(
        (dc.total_cases * b.manual_time) -
        (dc.self_service_cases * 10 + dc.collaborative_cases * 20 + dc.escalated_cases * 45)
    , 0) as time_saved_minutes,

    ROUND(
        ((dc.total_cases * b.manual_time) -
         (dc.self_service_cases * 10 + dc.collaborative_cases * 20 + dc.escalated_cases * 45)) / 60.0
    , 1) as time_saved_hours

FROM daily_cases dc
CROSS JOIN baseline b
LEFT JOIN daily_tokens dt ON dc.metric_date = dt.metric_date
LEFT JOIN daily_feedback df ON dc.metric_date = df.metric_date
ORDER BY dc.metric_date DESC;

-- -----------------------------------------------------
-- VIEW: Workflow Health
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_workflow_health AS
SELECT
    DATE(start_time) as execution_date,
    workflow_name,
    COUNT(*) as total_executions,
    COUNT(CASE WHEN status = 'success' THEN 1 END) as successful,
    COUNT(CASE WHEN status = 'failure' THEN 1 END) as failed,
    COUNT(CASE WHEN status = 'partial' THEN 1 END) as partial,
    ROUND(
        COUNT(CASE WHEN status = 'success' THEN 1 END)::numeric /
        NULLIF(COUNT(*), 0) * 100
    , 1) as success_rate,
    ROUND(AVG(duration_ms), 0) as avg_duration_ms,
    MAX(duration_ms) as max_duration_ms,
    MIN(duration_ms) as min_duration_ms
FROM workflow_executions
WHERE start_time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(start_time), workflow_name;

-- -----------------------------------------------------
-- VIEW: Improvement Opportunities Summary
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_improvement_summary AS
SELECT
    opportunity_type,
    COUNT(*) as total_opportunities,
    COUNT(CASE WHEN status = 'identified' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
    AVG(impact_score) as avg_impact,
    SUM(frequency) as total_occurrences
FROM improvement_opportunities
WHERE first_detected >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY opportunity_type;

-- -----------------------------------------------------
-- VIEW: Top Escalation Reasons
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_top_escalations AS
SELECT
    category,
    subcategory,
    COUNT(*) as escalation_count,
    AVG(confidence_score) as avg_confidence_at_escalation,
    ROUND(
        COUNT(*)::numeric /
        (SELECT COUNT(*) FROM cases WHERE escalated = TRUE AND created_at >= CURRENT_DATE - INTERVAL '30 days') * 100
    , 1) as pct_of_escalations
FROM cases
WHERE escalated = TRUE
  AND created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY category, subcategory
ORDER BY escalation_count DESC
LIMIT 10;

-- -----------------------------------------------------
-- VIEW: KB Coverage Analysis
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_kb_coverage AS
WITH case_categories AS (
    SELECT
        category,
        subcategory,
        COUNT(*) as case_count,
        AVG(CASE WHEN resolution_type LIKE 'self-service%' THEN 1 ELSE 0 END) as self_service_rate,
        AVG(confidence_score) as avg_confidence
    FROM cases
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY category, subcategory
),
kb_coverage AS (
    SELECT
        category,
        subcategory,
        COUNT(*) as article_count,
        AVG(success_count::numeric / NULLIF(view_count, 0)) as avg_success_rate
    FROM kb_articles
    GROUP BY category, subcategory
)
SELECT
    cc.category,
    cc.subcategory,
    cc.case_count,
    ROUND(cc.self_service_rate * 100, 1) as self_service_rate,
    ROUND(cc.avg_confidence, 2) as avg_confidence,
    COALESCE(kc.article_count, 0) as kb_articles,
    ROUND(COALESCE(kc.avg_success_rate, 0) * 100, 1) as kb_success_rate,
    CASE
        WHEN COALESCE(kc.article_count, 0) = 0 THEN 'No Coverage'
        WHEN cc.self_service_rate < 0.5 THEN 'Needs Improvement'
        WHEN cc.self_service_rate < 0.75 THEN 'Moderate'
        ELSE 'Good'
    END as coverage_status
FROM case_categories cc
LEFT JOIN kb_coverage kc ON cc.category = kc.category AND cc.subcategory = kc.subcategory
ORDER BY cc.case_count DESC;

-- -----------------------------------------------------
-- VIEW: Hourly Trends (for real-time dashboard)
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_hourly_trends AS
SELECT
    DATE_TRUNC('hour', created_at) as hour_bucket,
    COUNT(*) as cases,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
    AVG(confidence_score) as avg_confidence,
    AVG(resolution_time_minutes) FILTER (WHERE resolved_at IS NOT NULL) as avg_resolution_time
FROM cases
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY hour_bucket;

-- -----------------------------------------------------
-- VIEW: Executive Summary (single row current state)
-- -----------------------------------------------------

CREATE OR REPLACE VIEW v_executive_summary AS
WITH today_metrics AS (
    SELECT
        COUNT(*) as cases_today,
        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_today,
        AVG(satisfaction_score) FILTER (WHERE satisfaction_score IS NOT NULL) as csat_today,
        COUNT(CASE WHEN resolution_type LIKE 'self-service%' THEN 1 END) as self_service_today
    FROM cases
    WHERE DATE(created_at) = CURRENT_DATE
),
month_metrics AS (
    SELECT
        COUNT(*) as cases_month,
        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_month,
        AVG(satisfaction_score) FILTER (WHERE satisfaction_score IS NOT NULL) as csat_month
    FROM cases
    WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
),
token_metrics AS (
    SELECT
        SUM(total_tokens) as tokens_month,
        SUM(cost_usd) as cost_month
    FROM token_usage
    WHERE recorded_at >= DATE_TRUNC('month', CURRENT_DATE)
),
budget_metrics AS (
    SELECT
        SUM(token_limit) as total_budget,
        SUM(CASE WHEN tokens_used IS NOT NULL THEN tokens_used ELSE 0 END) as tokens_used
    FROM v_budget_utilization
    WHERE budget_type = 'monthly'
),
savings AS (
    SELECT
        SUM(cost_saved_usd) as total_savings_month,
        SUM(time_saved_hours) as total_hours_saved_month
    FROM v_daily_kpi
    WHERE metric_date >= DATE_TRUNC('month', CURRENT_DATE)
)
SELECT
    -- Today
    t.cases_today,
    ROUND(t.resolved_today::numeric / NULLIF(t.cases_today, 0) * 100, 1) as resolution_rate_today,
    ROUND(t.csat_today, 2) as csat_today,
    ROUND(t.self_service_today::numeric / NULLIF(t.cases_today, 0) * 100, 1) as self_service_rate_today,

    -- Month
    m.cases_month,
    ROUND(m.resolved_month::numeric / NULLIF(m.cases_month, 0) * 100, 1) as resolution_rate_month,
    ROUND(m.csat_month, 2) as csat_month,

    -- Tokens
    tk.tokens_month,
    ROUND(tk.cost_month, 2) as ai_cost_month,
    ROUND(b.tokens_used::numeric / NULLIF(b.total_budget, 0) * 100, 1) as budget_utilization_pct,

    -- Savings
    ROUND(s.total_savings_month, 2) as cost_savings_month,
    ROUND(s.total_hours_saved_month, 1) as hours_saved_month,

    -- Timestamp
    NOW() as generated_at

FROM today_metrics t
CROSS JOIN month_metrics m
CROSS JOIN token_metrics tk
CROSS JOIN budget_metrics b
CROSS JOIN savings s;

-- -----------------------------------------------------
-- FUNCTION: Calculate cost for token usage
-- -----------------------------------------------------

CREATE OR REPLACE FUNCTION calculate_token_cost()
RETURNS TRIGGER AS $$
DECLARE
    input_price DECIMAL(10, 4);
    output_price DECIMAL(10, 4);
BEGIN
    -- Get current pricing
    SELECT input_price_per_million, output_price_per_million
    INTO input_price, output_price
    FROM api_pricing
    WHERE provider = NEW.provider
      AND model = NEW.model
      AND is_current = TRUE
    LIMIT 1;

    -- Calculate cost if pricing found
    IF input_price IS NOT NULL THEN
        NEW.cost_usd := (NEW.input_tokens * input_price / 1000000) +
                        (NEW.output_tokens * output_price / 1000000);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic cost calculation
DROP TRIGGER IF EXISTS trg_calculate_token_cost ON token_usage;
CREATE TRIGGER trg_calculate_token_cost
    BEFORE INSERT ON token_usage
    FOR EACH ROW
    EXECUTE FUNCTION calculate_token_cost();

-- -----------------------------------------------------
-- FUNCTION: Update daily metrics snapshot
-- -----------------------------------------------------

CREATE OR REPLACE FUNCTION update_daily_metrics(target_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 day')
RETURNS VOID AS $$
BEGIN
    INSERT INTO daily_metrics (
        metric_date,
        total_cases,
        resolved_cases,
        escalated_cases,
        self_service_cases,
        collaborative_cases,
        avg_resolution_time_minutes,
        avg_satisfaction_score,
        satisfaction_responses,
        avg_confidence_score,
        ai_approvals,
        ai_edits,
        ai_rejections,
        anthropic_input_tokens,
        anthropic_output_tokens,
        anthropic_cost_usd,
        openai_input_tokens,
        openai_output_tokens,
        openai_cost_usd,
        estimated_time_saved_minutes,
        estimated_cost_saved_usd,
        workflow_executions,
        workflow_failures,
        avg_workflow_duration_ms
    )
    SELECT
        target_date,
        total_cases,
        resolved_cases,
        escalated_cases,
        self_service_cases,
        collaborative_cases,
        avg_resolution_time_min,
        avg_satisfaction_score,
        satisfaction_responses,
        avg_ai_confidence,
        ai_approvals,
        ai_edits,
        ai_rejections,
        anthropic_tokens,
        0, -- Would need separate tracking
        anthropic_cost_usd,
        openai_tokens,
        0,
        openai_cost_usd,
        time_saved_minutes::integer,
        cost_saved_usd,
        0, -- From workflow_executions
        0,
        0
    FROM v_daily_kpi
    WHERE metric_date = target_date
    ON CONFLICT (metric_date) DO UPDATE SET
        total_cases = EXCLUDED.total_cases,
        resolved_cases = EXCLUDED.resolved_cases,
        escalated_cases = EXCLUDED.escalated_cases,
        self_service_cases = EXCLUDED.self_service_cases,
        collaborative_cases = EXCLUDED.collaborative_cases,
        avg_resolution_time_minutes = EXCLUDED.avg_resolution_time_minutes,
        avg_satisfaction_score = EXCLUDED.avg_satisfaction_score,
        satisfaction_responses = EXCLUDED.satisfaction_responses,
        avg_confidence_score = EXCLUDED.avg_confidence_score,
        ai_approvals = EXCLUDED.ai_approvals,
        ai_edits = EXCLUDED.ai_edits,
        ai_rejections = EXCLUDED.ai_rejections,
        anthropic_input_tokens = EXCLUDED.anthropic_input_tokens,
        anthropic_cost_usd = EXCLUDED.anthropic_cost_usd,
        openai_input_tokens = EXCLUDED.openai_input_tokens,
        openai_cost_usd = EXCLUDED.openai_cost_usd,
        estimated_time_saved_minutes = EXCLUDED.estimated_time_saved_minutes,
        estimated_cost_saved_usd = EXCLUDED.estimated_cost_saved_usd;
END;
$$ LANGUAGE plpgsql;
