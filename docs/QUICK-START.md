# CX-Catalyst - Quick Start Guide

Get the AI-powered support system running in under 30 minutes.

---

## Prerequisites

Before starting, ensure you have:

- [ ] n8n instance (Cloud or self-hosted v1.0+)
- [ ] PostgreSQL database (Supabase recommended)
- [ ] API keys: Anthropic (Claude), OpenAI
- [ ] Slack workspace with bot permissions
- [ ] Gmail account for email integration

---

## Step 1: Database Setup (5 minutes)

Run the schema in your PostgreSQL database:

```bash
psql -h your-db-host -U postgres -d postgres -f schema.sql
```

Or copy the schema from `cx-catalyst-workflow.md` (Appendix: Database Schema section).

**Minimum tables needed for Quick Start:**
- `customers`
- `cases`
- `case_interactions`

---

## Step 2: Import Workflows (5 minutes)

1. Open n8n UI
2. Go to **Workflows** > **Import from File**
3. Import in order:
   - `workflow-1-smart-intake-triage.json`
   - `workflow-2-self-service-resolution.json`

> **Tip:** Start with just Workflows 1 & 2 for basic intake and self-service resolution.

---

## Step 3: Configure Credentials (10 minutes)

Create these credentials in n8n (**Settings** > **Credentials**):

| Credential | Type | Required For |
|------------|------|--------------|
| PostgreSQL | Database | All workflows |
| Anthropic API | API Key | AI classification & solutions |
| OpenAI API | API Key | Embeddings |
| Supabase | API Key | Vector store |
| Slack | OAuth2 | Notifications |

### Connect Credentials to Nodes

1. Open each imported workflow
2. Click nodes with red warning indicators
3. Select your configured credential from the dropdown
4. Save the workflow

---

## Step 4: Set Environment Variables (5 minutes)

In n8n: **Settings** > **Environment Variables**

```
N8N_WEBHOOK_BASE_URL=https://your-n8n-instance.com
```

---

## Step 5: Activate & Test (5 minutes)

### Activate Workflow 1

1. Open **Workflow 1: Smart Intake & Triage**
2. Toggle **Active** (top right)
3. Copy the webhook URL shown

### Send Test Request

```bash
curl -X POST https://your-n8n.com/webhook/support/intake \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "test-001",
    "customer_email": "test@example.com",
    "customer_name": "Test User",
    "description": "Cannot login to my account",
    "severity": "medium",
    "product": "web-portal"
  }'
```

### Expected Response

```json
{
  "success": true,
  "case_id": "uuid-here",
  "status": "triaged",
  "message": "Your support request has been received..."
}
```

---

## What's Working Now

With Workflows 1 & 2 active:

1. **Intake** - Support requests received via webhook
2. **AI Classification** - Automatic categorization and priority
3. **Smart Routing** - Cases route to self-service or escalation
4. **Self-Service** - AI-generated solutions for simple issues

---

## Next Steps

### Add More Workflows

| Workflow | Purpose | When to Add |
|----------|---------|-------------|
| 3 - Proactive Detection | Monitor for issues | After basic flow works |
| 4 - Collaborative Support | Human-in-loop | When team is ready |
| 5 - Continuous Learning | Daily insights | After 1 week of data |

### Set Up Confluence Knowledge Base

**This is critical for AI resolution quality!**

1. Create a Confluence space for support articles
2. Populate with 20-50 core articles (see [Confluence Integration Guide](CONFLUENCE-INTEGRATION.md))
3. Run the indexing workflow to generate embeddings
4. Test vector search retrieval

**Quick Setup:**
```bash
# See the Confluence Integration Guide for:
- Creating API credentials
- Setting up Supabase vector store
- Creating the indexing workflow
- Writing effective KB articles
```

### Configure Additional Integrations

- **Jira** - For bug tickets and escalations
- **Gmail** - For email support channel

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Webhook not responding | Ensure workflow is **Active** |
| Database errors | Check PostgreSQL credentials and schema |
| AI errors | Verify Anthropic API key and quota |
| Empty classification | Ensure customer exists in database |

### Check Logs

1. Open workflow
2. Click **Executions** tab
3. Review node outputs for errors

---

## Support

- Full documentation: `docs/` folder
- Design document: `cx-catalyst-workflow.md`
- Workflow README: `n8n-workflows/README.md`

---

*Quick Start Guide v1.0 - January 2026*
