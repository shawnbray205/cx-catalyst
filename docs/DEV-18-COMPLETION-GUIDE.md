# DEV-18: KB Article Vector Indexing for Semantic Search

## Completion Guide

This document outlines the steps to complete Jira DEV-18 - enabling KB article vector indexing for semantic search.

---

## Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| pgvector Extension | ✅ Enabled | Supabase has vector extension |
| confluence_kb Table | ✅ Created | With VECTOR(1536) column |
| Demo KB Articles | ✅ Imported | 24 articles without embeddings |
| Embedding Workflow v2 | ✅ Created | `workflow-kb-embedding-generator-v2.json` |
| Workflow 5 Re-index Node | ⚠️ Disabled | Needs to be enabled after webhook is active |

---

## Implementation Steps

### Step 1: Import Updated Embedding Workflow

1. Open n8n editor
2. Create a new workflow (or update existing "KB Article Embedding Generator")
3. Import the JSON from:
   ```
   cx-catalyst/n8n-workflows/workflow-kb-embedding-generator-v2.json
   ```
4. Update credential references:
   - `postgres-credential-id` → Your Supabase PostgreSQL credential
   - `openai-credential-id` → Your OpenAI API credential

### Step 2: Configure Credentials

**PostgreSQL (Supabase)**
- Should already be configured from existing workflows
- Verify it can access the `confluence_kb` table

**OpenAI API**
- Required for `text-embedding-3-small` model
- Ensure API key has embeddings access

### Step 3: Activate the Webhook

1. In the imported workflow, click on "Webhook Trigger" node
2. Copy the webhook URL (format: `https://your-n8n-instance/webhook/confluence/reindex`)
3. Activate the workflow (toggle to active)
4. The webhook will now be available at `/webhook/confluence/reindex`

### Step 4: Set Environment Variable

In n8n Settings → Environment Variables, add:
```
N8N_WEBHOOK_BASE_URL=https://your-n8n-instance.com
```

This is used by Workflow 5's "Trigger KB Re-index" node.

### Step 5: Enable Trigger in Workflow 5

1. Open "Support - 5. Continuous Learning & Improvement (Enhanced)"
2. Find the "Trigger KB Re-index" node (currently disabled)
3. Click on the node → Enable it
4. Verify the URL expression: `={{ $env.N8N_WEBHOOK_BASE_URL }}/webhook/confluence/reindex`
5. Save the workflow

### Step 6: Generate Initial Embeddings

Run the embedding workflow manually to process all 24 demo KB articles:

1. Open "KB Article Embedding Generator v2"
2. Click "Execute Workflow"
3. Wait for completion (processes 50 articles per run)
4. Verify embeddings were generated:

```sql
SELECT page_id, title,
       CASE WHEN embedding IS NOT NULL THEN 'Yes' ELSE 'No' END as has_embedding
FROM confluence_kb
ORDER BY space_key, title;
```

---

## Workflow Details

### KB Article Embedding Generator v2

**File:** `workflow-kb-embedding-generator-v2.json`

**Triggers:**
- Webhook: `POST /webhook/confluence/reindex`
- Manual: Click "Execute Workflow"

**Flow:**
1. Fetches articles from `confluence_kb` where `embedding IS NULL`
2. Prepares text (title + metadata + content)
3. Calls OpenAI API for embeddings (text-embedding-3-small, 1536 dimensions)
4. Updates `confluence_kb` with embedding vector
5. Returns JSON response with count of articles processed

**Request Body (optional):**
```json
{
  "page_ids": ["specific-page-id"],  // Optional: only process specific pages
  "source": "workflow-5",             // Optional: tracking
  "priority": "high"                  // Optional: tracking
}
```

**Response:**
```json
{
  "success": true,
  "articles_processed": 24,
  "message": "Successfully generated embeddings for 24 articles",
  "timestamp": "2026-01-23T12:00:00.000Z"
}
```

### Integration with Workflow 5

When Workflow 5 creates a new Confluence KB article:
1. Create Confluence Page → Add Labels
2. Trigger KB Re-index (HTTP Request to webhook)
3. Log to PostgreSQL

The re-index webhook triggers immediate embedding generation for the new article.

---

## Testing

### Test 1: Manual Embedding Generation

```bash
# Run the workflow manually in n8n and check results
```

### Test 2: Webhook Trigger

```bash
curl -X POST https://your-n8n-instance/webhook/confluence/reindex \
  -H "Content-Type: application/json" \
  -d '{"source": "test"}'
```

### Test 3: Verify Embeddings in Database

```sql
-- Count articles with/without embeddings
SELECT
  CASE WHEN embedding IS NOT NULL THEN 'Has Embedding' ELSE 'No Embedding' END as status,
  COUNT(*) as count
FROM confluence_kb
GROUP BY status;

-- Test semantic search (requires an embedding)
SELECT page_id, title,
       1 - (embedding <=> (SELECT embedding FROM confluence_kb WHERE page_id = 'DEMO_ENT_001')) as similarity
FROM confluence_kb
WHERE embedding IS NOT NULL
ORDER BY similarity DESC
LIMIT 5;
```

### Test 4: End-to-End with Workflow 2

Submit a test support case that should match KB content and verify:
1. Workflow 2 performs semantic search
2. Relevant KB articles are retrieved
3. Similarity scores are reasonable (> 0.7)

---

## Differences from Original Workflow

| Aspect | Original (v1) | Updated (v2) |
|--------|--------------|--------------|
| Table | `kb_articles` | `confluence_kb` |
| Trigger | Manual only | Webhook + Manual |
| Response | None | JSON response for webhook |
| Columns | `article_id` | `id`, `page_id` |
| Update | `updated_at` only | `updated_at` + `last_indexed_at` |

---

## Troubleshooting

### Embeddings Not Generating

1. Check OpenAI API key is valid
2. Verify `confluence_kb` table has articles with content
3. Check workflow execution logs for errors

### Webhook Returns 404

1. Verify workflow is active
2. Check webhook URL path matches `/webhook/confluence/reindex`
3. Verify n8n instance is accessible

### Workflow 5 Re-index Fails

1. Check `N8N_WEBHOOK_BASE_URL` environment variable
2. Verify the embedding workflow is active
3. Check network connectivity between workflows

### Slow Embedding Generation

- Normal: ~1-2 seconds per article
- OpenAI API has rate limits; workflow processes 50 articles max per run
- For large batches, run multiple times

---

## Cost Estimate

| Model | Price per 1M tokens | Est. tokens/article | Cost/article |
|-------|---------------------|---------------------|--------------|
| text-embedding-3-small | $0.02 | ~500 | $0.00001 |

For 24 demo articles: ~$0.00024 total

---

*DEV-18 Completion Guide - January 2026*
