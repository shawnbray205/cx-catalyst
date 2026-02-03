# CX-Catalyst - Error Reference

Comprehensive reference for all error codes, error responses, and diagnostic procedures.

---

## Table of Contents

1. [API Error Codes](#api-error-codes)
2. [Workflow Execution Errors](#workflow-execution-errors)
3. [AI Service Errors](#ai-service-errors)
4. [Database Errors](#database-errors)
5. [Integration Errors](#integration-errors)
6. [Vector Search Errors](#vector-search-errors)
7. [Product Error Codes](#product-error-codes)
8. [Diagnostic Procedures](#diagnostic-procedures)

---

## API Error Codes

Errors returned by the CX-Catalyst webhook API endpoints.

| Code | HTTP Status | Description | Resolution |
|------|-------------|-------------|------------|
| `VALIDATION_ERROR` | 400 | Invalid request data | Check request body against the API Reference schema |
| `MISSING_FIELD` | 400 | Required field not provided | Include all required fields (customer_email, customer_name, description) |
| `INVALID_FORMAT` | 400 | Field format incorrect | Verify email format, UUID format, enum values |
| `NOT_FOUND` | 404 | Case or resource not found | Verify the case_id or resource ID exists |
| `ALREADY_PROCESSED` | 409 | Action already taken on this case | Case was already approved/rejected/resolved |
| `RATE_LIMITED` | 429 | Too many requests | Wait and retry after the `retry_after` period |
| `INTERNAL_ERROR` | 500 | System error | Check n8n execution logs for the failing workflow |
| `SERVICE_UNAVAILABLE` | 503 | Dependency unavailable | Check status of Supabase, Anthropic, OpenAI, Confluence |

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "affected_field",
      "suggestion": "How to fix this"
    }
  },
  "timestamp": "2026-01-15T10:30:00Z"
}
```

---

## Workflow Execution Errors

Errors that occur during n8n workflow execution.

### Workflow 1: Smart Intake & Triage

| Error | Cause | Resolution |
|-------|-------|------------|
| Webhook timeout | Workflow execution exceeds timeout | Increase `EXECUTIONS_TIMEOUT` in n8n settings |
| Customer lookup failed | Customer not found in database | Workflow auto-creates customer record; check DB connection |
| Classification failed | AI API returned an error | Check Anthropic API key and quota |
| Routing error | Confidence score parsing failed | Verify AI response format matches expected JSON schema |

### Workflow 2: Self-Service Resolution

| Error | Cause | Resolution |
|-------|-------|------------|
| KB search returned no results | No matching articles in vector store | Check embedding index; ensure articles are indexed |
| Solution generation failed | AI API error during solution creation | Check API key, rate limits, and prompt size |
| Email delivery failed | Gmail credential expired | Re-authorize Gmail OAuth in n8n credentials |
| Approval link expired | Customer clicked link after case was already resolved | No action needed; inform customer case is resolved |

### Workflow 3: Proactive Detection

| Error | Cause | Resolution |
|-------|-------|------------|
| Schedule trigger missed | n8n was down during scheduled execution | Workflow will run at next interval; check n8n uptime |
| Health metrics query failed | Database connection error | Check PostgreSQL credentials and network access |
| Jira ticket creation failed | Invalid project key or issue type | Verify Jira configuration matches project setup |
| Alert threshold not configured | Missing environment variables | Set `CONFIDENCE_THRESHOLD_HIGH` and related variables |

### Workflow 4: Collaborative Support Hub

| Error | Cause | Resolution |
|-------|-------|------------|
| Slack message failed | Bot token invalid or channel not found | Re-authorize Slack bot; verify channel names |
| Review timeout missed | Timeout scheduler error | Check Wait node configuration (2-hour default) |
| Edit submission failed | Malformed edited solution JSON | Validate the edit form submission format |
| Escalation routing error | Senior queue channel not configured | Create #support-alerts channel and update workflow |

### Workflow 5: Continuous Learning

| Error | Cause | Resolution |
|-------|-------|------------|
| Analysis query timeout | Large dataset with complex aggregation | Add date range filters to limit query scope |
| Confluence page creation failed | Space doesn't exist or auth error | Verify PKB space exists; check Confluence credentials |
| Report email failed | SMTP/Gmail error | Check email credentials and recipient addresses |
| KB gap detection returned empty | No cases in the analysis window | Normal if no new cases; check date range |

---

## AI Service Errors

Errors from the Anthropic (Claude) and OpenAI APIs.

### Anthropic API Errors

| HTTP Status | Error | Cause | Resolution |
|-------------|-------|-------|------------|
| 400 | `invalid_request_error` | Malformed request or prompt too long | Reduce prompt size; check JSON formatting |
| 401 | `authentication_error` | Invalid API key | Regenerate key at console.anthropic.com |
| 403 | `permission_error` | Key lacks required permissions | Check API key tier and permissions |
| 429 | `rate_limit_error` | Too many requests | Add delays between calls; check rate limit tier |
| 500 | `api_error` | Anthropic service error | Retry with exponential backoff; check status.anthropic.com |
| 529 | `overloaded_error` | API overloaded | Retry after delay; consider queuing requests |

### OpenAI API Errors (Embeddings)

| HTTP Status | Error | Cause | Resolution |
|-------------|-------|-------|------------|
| 400 | `invalid_request_error` | Input too long for embedding model | Chunk text to under 8,191 tokens for text-embedding-3-small |
| 401 | `invalid_api_key` | Invalid API key | Regenerate at platform.openai.com |
| 429 | `rate_limit_exceeded` | Token or request limit hit | Add batch delays; check usage dashboard |
| 500 | `server_error` | OpenAI service error | Retry with backoff; check status.openai.com |

---

## Database Errors

### PostgreSQL Connection Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `ECONNREFUSED` | Database not reachable | Check host, port, and network/firewall rules |
| `FATAL: password authentication failed` | Wrong credentials | Verify username and password in n8n credential |
| `FATAL: database "X" does not exist` | Wrong database name | Verify database name (default: `support_system`) |
| `SSL connection required` | SSL not configured | Enable SSL in the n8n PostgreSQL credential |
| `too many connections` | Connection pool exhausted | Increase `max_connections` in PostgreSQL config or reduce concurrent workflows |

### Query Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `relation "X" does not exist` | Table missing | Run the schema migration from ADMIN-GUIDE.md |
| `column "X" does not exist` | Schema mismatch | Check column names match the expected schema |
| `duplicate key value violates unique constraint` | Attempting to insert duplicate | Use UPSERT (ON CONFLICT) or check for existing records |
| `value too long for type character varying(N)` | Input exceeds column length | Truncate input or increase column size |

---

## Integration Errors

### Confluence Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Space does not exist` | Wrong space key | Verify space key (default: `PKB`) |
| `A page with this title already exists` | Duplicate page title | Implement upsert logic or delete/rename existing page |
| 401 Unauthorized | Invalid HTTP Basic Auth | Check email + API token from id.atlassian.com |
| 403 Forbidden | Insufficient permissions | Grant write access to the API user for the space |

### Slack Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `channel_not_found` | Channel doesn't exist or bot not added | Create channel; invite bot with `/invite @bot-name` |
| `not_authed` | Invalid bot token | Re-authorize Slack OAuth in n8n |
| `missing_scope` | Bot lacks required permissions | Add scopes: chat:write, channels:read, reactions:write |
| `rate_limited` | Too many Slack API calls | Add 1-second delays between consecutive Slack messages |

### Jira Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Project not found` | Wrong project key | Verify project key in Jira settings |
| `Issue type not found` | Invalid issue type name | Check exact name (case-sensitive): Bug, Task, Incident |
| Field validation errors | Missing required fields | Query issue type metadata to check required fields |
| ADF formatting error | Invalid description format | Use Atlassian Document Format or plain text |

### Gmail Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `invalid_grant` | OAuth token expired | Re-connect Gmail credential in n8n |
| `insufficientPermissions` | Missing API scopes | Re-authorize with gmail.send, gmail.readonly scopes |
| `rateLimitExceeded` | Daily send limit reached | Gmail: 500/day; Workspace: 2,000/day |

---

## Vector Search Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| Empty search results | No documents in vector store | Run the KB Embedding Generator workflow |
| Low similarity scores | Embeddings out of date or poor article quality | Re-index; improve article titles and content |
| Dimension mismatch | Embedding model changed | Ensure all embeddings use text-embedding-3-small (1536 dimensions) |
| `match_documents` function not found | Missing database function | Run the vector store setup SQL from ADMIN-GUIDE.md |
| Search timeout | Index too large or missing | Create IVFFlat index on the embedding column |

---

## Product Error Codes

These are error codes that customers may report in their support requests. The `error_codes` database table tracks known error codes and their resolutions.

### Error Code Format

Product error codes follow the pattern: `ERR_{CATEGORY}_{NUMBER}`

| Category Prefix | Domain | Examples |
|----------------|--------|----------|
| `ERR_AUTH_` | Authentication and login | `ERR_AUTH_001` (Invalid token), `ERR_AUTH_002` (Session expired) |
| `ERR_BILL_` | Billing and payments | `ERR_BILL_001` (Payment declined), `ERR_BILL_002` (Invalid plan) |
| `ERR_CFG_` | Configuration | `ERR_CFG_001` (Invalid setting), `ERR_CFG_002` (Missing required config) |
| `ERR_API_` | API errors | `ERR_API_001` (Rate limit), `ERR_API_002` (Invalid endpoint) |
| `ERR_PERF_` | Performance | `ERR_PERF_001` (Timeout), `ERR_PERF_002` (Memory exceeded) |
| `ERR_INT_` | Integrations | `ERR_INT_001` (Connection failed), `ERR_INT_002` (Sync error) |

### Managing Error Codes

Error codes are stored in the `error_codes` table:

```sql
-- View all error codes
SELECT error_code, product, description, severity,
       automated_fix_available, occurrence_count
FROM error_codes
ORDER BY occurrence_count DESC;

-- Add a new error code
INSERT INTO error_codes (error_code, product, description, severity,
                         diagnostic_steps, resolution_steps, automated_fix_available)
VALUES (
  'ERR_AUTH_003',
  'web-portal',
  'MFA verification timeout',
  'medium',
  ARRAY['Check MFA device sync', 'Verify time settings'],
  ARRAY['Reset MFA enrollment', 'Generate backup codes'],
  false
);
```

The AI uses error codes for direct-match resolution — when a customer reports an error code, the system looks it up directly before falling back to vector search.

---

## Diagnostic Procedures

### General Troubleshooting Steps

1. **Check n8n execution logs** — Workflows > [workflow name] > Executions
2. **Review node outputs** — Click on a failed execution to see each node's input/output
3. **Check API dashboards** — Anthropic, OpenAI, and Supabase dashboards show usage and errors
4. **Query the database** — Use the SQL queries from ADMIN-GUIDE.md Appendix for system health checks
5. **Check Slack alerts** — The #support-alerts channel receives notifications of critical failures

### Health Check Queries

```sql
-- Recent workflow execution failures
SELECT workflow_name, error_message, COUNT(*) as failures
FROM workflow_executions
WHERE status = 'error'
  AND start_time > NOW() - INTERVAL '24 hours'
GROUP BY workflow_name, error_message
ORDER BY failures DESC;

-- Cases stuck in processing
SELECT case_id, status, created_at,
       NOW() - created_at as age
FROM cases
WHERE status IN ('new', 'triaged', 'in_progress')
  AND created_at < NOW() - INTERVAL '2 hours'
ORDER BY created_at;

-- API error frequency
SELECT DATE(start_time) as date,
       workflow_name,
       COUNT(CASE WHEN status = 'error' THEN 1 END) as errors,
       COUNT(*) as total
FROM workflow_executions
WHERE start_time > NOW() - INTERVAL '7 days'
GROUP BY date, workflow_name
ORDER BY date DESC, errors DESC;
```

---

*Error Reference v1.0 - January 2026*
