# CX-Catalyst - n8n Workflows

This folder contains 5 n8n workflow JSON files implementing the AI-powered customer support transformation system.

## Workflows Overview

| # | Workflow | Purpose | Trigger |
|---|----------|---------|---------|
| 1 | Smart Support Intake & Triage | Receive, classify, and route support requests | Webhook POST |
| 2 | Self-Service Resolution Engine | Auto-resolve simple issues with KB/AI | Called from WF1 |
| 3 | Proactive Issue Detection | Monitor systems and prevent issues | Schedule (15 min) |
| 4 | Collaborative Support Hub | Human-in-loop for complex cases | Called from WF1 |
| 5 | Continuous Learning | Analyze patterns and improve system | Schedule (daily 3 AM) |

## Quick Start

### 1. Import Workflows

1. Open n8n UI
2. Go to **Workflows** > **Import from File**
3. Import each JSON file in order (1-5)

### 2. Configure Credentials

Each workflow requires credentials. Create these in n8n:

| Credential Type | Required For |
|-----------------|--------------|
| PostgreSQL | All workflows (case data) |
| Anthropic API | All workflows (Claude AI) |
| OpenAI API | WF2, WF4 (embeddings) |
| Supabase | WF2, WF4 (vector store) |
| Slack | All workflows (notifications) |
| Gmail | WF2, WF4, WF5 (emails) |
| Jira | WF3, WF5 (tickets) |

### 3. Update Credential References

After importing, update each node's credential references:
1. Open workflow
2. Click on nodes with red indicators
3. Select your configured credential

### 4. Set Environment Variables

Configure these in n8n Settings > Environment Variables:

```
N8N_WEBHOOK_BASE_URL=https://your-n8n-instance.com
JIRA_CLOUD_ID=your-jira-cloud-id
GITHUB_TOKEN=your-github-token
GITHUB_REPO=your-org/your-repo
LOG_AGGREGATOR_URL=http://your-log-service:9200
LEADERSHIP_EMAIL=support-leadership@company.com
SUPPORT_TEAM_EMAIL=support-team@company.com
```

### 5. Database Setup

Run the PostgreSQL schema from the main design document to create required tables:
- customers
- cases
- case_interactions
- kb_articles
- error_codes
- health_metrics
- proactive_alerts
- review_queue
- workflow_executions
- agent_feedback

## Webhook Endpoints

After activation, these endpoints will be available:

| Endpoint | Method | Workflow |
|----------|--------|----------|
| `/webhook/support/intake` | POST | WF1 - Intake |
| `/webhook/support/self-service` | POST | WF2 - Self-service |
| `/webhook/support/approve/:caseId` | GET | WF2 - Approval |
| `/webhook/support/feedback/:caseId` | GET | WF2 - Feedback |
| `/webhook/support/collaborative` | POST | WF4 - Collaborative |
| `/webhook/support/review/:reviewId/:action` | GET | WF4 - Review |

## Testing

### Test Intake Webhook

```bash
curl -X POST https://your-n8n.com/webhook/support/intake \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "test-customer-123",
    "customer_email": "test@example.com",
    "customer_name": "Test User",
    "description": "I cannot login to my account. Getting error code ERR_AUTH_001.",
    "severity": "high",
    "product": "enterprise-gateway",
    "environment": "production"
  }'
```

### Expected Response

```json
{
  "success": true,
  "case_id": "uuid-here",
  "request_id": "REQ-timestamp-random",
  "status": "triaged",
  "classification": {
    "category": "configuration",
    "priority": "high",
    "resolution_path": "self-service"
  },
  "message": "Your support request has been received...",
  "estimated_response_time": "Within 2 hours"
}
```

## Architecture

```
[Customer Request]
        ↓
[WF1: Intake & Triage] ──────────────────────────┐
        ↓                                         │
   [Route Decision]                               │
        ↓                                         │
   ┌────┴────┬────────────┐                      │
   ↓         ↓            ↓                      │
[WF2]     [WF4]      [Escalate]                  │
Self-    Collab-     to Human                    │
Service  orative                                 │
        ↓                                        │
   [Resolution]                                  │
        ↓                                        │
   [Feedback Loop] ──────────────────────────────┤
                                                 │
[WF3: Proactive Detection] ──── Alerts ──────────┤
        ↓                                        │
   [Prevention]                                  │
                                                 │
[WF5: Continuous Learning] ←─────────────────────┘
        ↓
   [KB Updates]
   [Bug Reports]
   [Insights]
```

## Customization

### Adjusting AI Confidence Thresholds

In WF1 (Intake), modify the Switch node conditions:
- Self-service: confidence >= 0.85 AND simple
- Collaborative: confidence >= 0.60
- Escalate: confidence < 0.60 OR complex

### Changing Proactive Detection Interval

In WF3, modify the Schedule trigger:
- Default: Every 15 minutes
- Adjust based on your monitoring needs

### Modifying Agent Prompts

Each workflow contains agent prompts in the respective nodes. Customize these based on:
- Your product terminology
- Company tone and style
- Specific classification categories

### Adding Confluence Knowledge Base

**IMPORTANT**: Workflows 2 and 4 require Confluence integration for optimal performance.

To add Confluence KB search to your workflows:

1. **Set up Confluence** - Follow the [Confluence Integration Guide](../docs/CONFLUENCE-INTEGRATION.md)
2. **Create indexing workflow** - Build the Confluence KB Indexer
3. **Modify Workflow 2** - Add vector search before AI generation:
   ```
   [Classify Issue]
        ↓
   [Generate Query Embedding] (OpenAI)
        ↓
   [Search Vector DB] (Supabase)
        ↓
   [Fetch Confluence Pages] (Top 5 results)
        ↓
   [AI Generate Solution] (Include KB context)
   ```
4. **Update Workflow 5** - Enable automatic KB page creation
5. **Test thoroughly** - Verify KB retrieval improves resolution quality

See `docs/CONFLUENCE-INTEGRATION.md` for detailed implementation steps.

### NEW: Confluence KB Indexer Workflow

> **⚠️ Important**: Uses **HTTP Request nodes** with Confluence REST API, not dedicated Confluence nodes. See `../DOCUMENTATION-UPDATES.md` for details.

A new workflow has been added for indexing Confluence pages:

**File:** `workflow-confluence-kb-indexer.json`

**What it does:**
- Fetches all pages from Confluence SUPPORT space (HTTP Request to REST API)
- Splits response array into individual items
- Cleans HTML and formats content for embeddings
- Generates embeddings via OpenAI (text-embedding-3-small)
- Stores in Supabase vector database with LangChain nodes
- Runs daily at 2 AM automatically
- Sends Slack notification on completion

**To use:**
1. Import `workflow-confluence-kb-indexer.json`
2. Create **HTTP Basic Auth** credential (email + API token from id.atlassian.com)
3. Update credential IDs in all nodes
4. Replace `YOUR-COMPANY` with your Atlassian subdomain
5. Test with "Execute Workflow"
6. Activate for daily runs

**API Endpoint:** `GET https://your-company.atlassian.net/wiki/rest/api/content`

**See:** `CONFLUENCE-WORKFLOW-MODIFICATIONS.md` for complete integration instructions, including:
- Exact node configurations
- Step-by-step modifications for Workflows 2 and 5
- Testing procedures
- Rollback plans

## Troubleshooting

### Common Issues

1. **Webhook not responding**: Ensure workflow is activated
2. **DB connection errors**: Verify PostgreSQL credentials and network access
3. **AI errors**: Check Anthropic API key and rate limits
4. **Missing data**: Verify database tables exist with correct schema

### Debug Mode

1. Open workflow in n8n
2. Use "Execute Workflow" with test data
3. Check each node's output
4. Review execution logs

## Support

For issues with these workflows, check:
1. n8n execution logs
2. PostgreSQL query results
3. AI agent outputs
4. Integration API responses

---

*Generated for CX-Catalyst Project - January 2026*
