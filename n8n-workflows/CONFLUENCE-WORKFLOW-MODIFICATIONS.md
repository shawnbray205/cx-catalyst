# Confluence Workflow Modifications Guide

This document describes the exact modifications needed to integrate Confluence KB into existing workflows.

---

## Overview

The existing workflows already have vector search (Supabase) for knowledge base articles. To complete the Confluence integration, we need to:

1. ✅ **NEW**: Add Confluence KB Indexer workflow (already created)
2. 🔧 **MODIFY**: Enhance Workflow 2 to fetch full Confluence pages
3. 🔧 **MODIFY**: Add Confluence page creation to Workflow 5

---

## 1. New Workflow: Confluence KB Indexer ✅

**File:** `workflow-confluence-kb-indexer.json` (CREATED)

**Purpose:** Index all Confluence pages into Supabase vector database

**Nodes:**
1. Manual Trigger (for testing)
2. Schedule Trigger (Daily at 2 AM)
3. Get All Confluence Pages
4. Clean & Format Content
5. Generate Embeddings (OpenAI)
6. Upsert to Supabase
7. Summarize Results
8. Notify Slack
9. Log Execution

**Setup Required:**
- Replace `YOUR_CONFLUENCE_CREDENTIAL_ID` with actual Confluence credential
- Replace `YOUR_OPENAI_CREDENTIAL_ID` with actual OpenAI credential
- Replace `YOUR_SUPABASE_CREDENTIAL_ID` with actual Supabase credential
- Update `YOUR-COMPANY.atlassian.net` with your actual domain
- Change `SUPPORT` space key if different

**To Import:**
1. Open n8n UI
2. Go to Workflows > Import from File
3. Select `workflow-confluence-kb-indexer.json`
4. Update all credential references
5. Test with "Execute Workflow"
6. Activate once working

---

## 2. Modify Workflow 2: Self-Service Resolution

**File:** `workflow-2-self-service-resolution.json`

**Current State:** ✅ Already has KB Vector Search (Supabase)

**What's Already Working:**
- Vector search returns similar KB articles
- Results include page IDs and content snippets

**What Needs to be Added:** Fetch full Confluence page content

### Option A: Store Full Content in Supabase (Recommended)

**No workflow changes needed!** The indexer already stores full page content in the `confluence_kb.content` field.

**Current vector search node** (line 68-86) already retrieves full content:
```json
{
  "parameters": {
    "mode": "raw",
    "query": "={{ $json.description }} {{ $json.classification.category }}",
    "topK": 5
  },
  "name": "KB Vector Search",
  "type": "@n8n/n8n-nodes-langchain.vectorStoreSupabase"
}
```

**This returns:**
- `page_id`
- `title`
- `content` (full text, already cleaned)
- `url`
- `metadata`
- `similarity` score

**Action Required:** ✅ None - already complete!

### Option B: Fetch Live from Confluence (Alternative)

If you want to fetch the latest content from Confluence in real-time:

**Add new node after "KB Vector Search":**

```json
{
  "parameters": {
    "method": "GET",
    "url": "=https://YOUR-COMPANY.atlassian.net/wiki/rest/api/content/{{ $json.page_id }}?expand=body.storage,version",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpBasicAuth",
    "options": {
      "response": {
        "response": {
          "responseFormat": "json"
        }
      }
    }
  },
  "id": "fetch-confluence-page",
  "name": "Fetch Confluence Page Content",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [900, 600],
  "credentials": {
    "httpBasicAuth": {
      "id": "YOUR_CONFLUENCE_CREDENTIAL_ID",
      "name": "Confluence API (Basic Auth)"
    }
  }
}
```

> **Note**: This uses the HTTP Request node with Confluence REST API. Create Basic Auth credentials with your Atlassian email and API token.

**Pros:**
- Always fetches latest content
- Shows recent updates immediately

**Cons:**
- Additional API call (slower)
- Confluence API rate limits
- More complexity

**Recommendation:** Use Option A (stored content) and rely on daily indexer to keep content fresh.

---

## 3. Modify Workflow 2: Update AI Agent Prompt

**Current AI Agent Node:** Already exists in workflow

**Enhancement Needed:** Ensure the AI prompt includes KB context

**Find the AI Agent node** (around line 120-200) and verify the prompt includes:

```javascript
You are a customer support AI assistant.

Customer Issue:
{{ $json.description }}

Classification:
- Category: {{ $json.classification.category }}
- Priority: {{ $json.classification.priority }}
- Product: {{ $json.product }}

Relevant Knowledge Base Articles:
{{ $json.kb_results.map((article, idx) => `
--- Article ${idx + 1} ---
Title: ${article.title}
URL: ${article.url}
Similarity: ${(article.similarity * 100).toFixed(0)}%
Content:
${article.content}
`).join('\n') }}

Based on the customer's issue and the relevant KB articles above, provide:
1. A clear, personalized solution
2. Step-by-step instructions (numbered list)
3. Links to the most relevant KB articles (markdown format)
4. Any prerequisites or warnings

Keep the response concise, actionable, and customer-friendly.
Include at least 1-2 KB article links for the customer to reference.
```

**To Update:**
1. Open workflow 2 in n8n UI
2. Find the "AI Agent" or "LLM Chat" node
3. Update the system prompt to include KB context
4. Save workflow

---

## 4. Modify Workflow 5: Continuous Learning

**File:** `workflow-5-continuous-learning.json`

**Add Confluence Page Creation for Knowledge Gaps**

### Step-by-Step Modifications:

#### A. Add Analysis Node (After existing gap analysis)

**Insert new Code node:**

```json
{
  "parameters": {
    "jsCode": "// Identify cases that need new KB articles\nconst items = $input.all();\nconst knowledgeGaps = [];\n\nfor (const item of items) {\n  const caseData = item.json;\n  \n  // Check if case was resolved successfully but had no KB match\n  if (\n    caseData.resolution_successful === true &&\n    (caseData.kb_match_score < 0.7 || !caseData.kb_pages_retrieved)\n  ) {\n    knowledgeGaps.push({\n      category: caseData.classification.category,\n      subcategory: caseData.classification.subcategory,\n      issue_description: caseData.description,\n      solution_provided: caseData.resolution,\n      frequency: 1\n    });\n  }\n}\n\n// Group by category and subcategory\nconst grouped = {};\nfor (const gap of knowledgeGaps) {\n  const key = `${gap.category}:${gap.subcategory}`;\n  if (!grouped[key]) {\n    grouped[key] = {\n      category: gap.category,\n      subcategory: gap.subcategory,\n      cases: [],\n      frequency: 0\n    };\n  }\n  grouped[key].cases.push(gap);\n  grouped[key].frequency++;\n}\n\n// Convert to array and filter by frequency (at least 3 cases)\nconst significantGaps = Object.values(grouped)\n  .filter(g => g.frequency >= 3)\n  .sort((a, b) => b.frequency - a.frequency);\n\nreturn significantGaps.map(gap => ({ json: gap }));"
  },
  "id": "identify-kb-gaps",
  "name": "Identify KB Gaps",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [1200, 300]
}
```

#### B. Add AI Article Generation Node

**Insert new AI Agent node:**

```json
{
  "parameters": {
    "text": "=You are a technical writer creating knowledge base articles.\n\nBased on these {{ $json.frequency }} resolved support cases, create a comprehensive Confluence KB article.\n\nCategory: {{ $json.category }}\nSubcategory: {{ $json.subcategory }}\n\nSample Cases:\n{{ $json.cases.slice(0, 5).map((c, i) => `\nCase ${i+1}:\nIssue: ${c.issue_description}\nSolution: ${c.solution_provided}`).join('\\n---\\n') }}\n\nCreate an article using this structure:\n\n<h2>Problem Statement</h2>\n<p>[Clear description of the issue customers face]</p>\n\n<h2>Affected Users</h2>\n<ul>\n<li><strong>Product:</strong> [Which product/plan]</li>\n<li><strong>Environment:</strong> [Production/Staging/All]</li>\n<li><strong>Frequency:</strong> [Common/Occasional/Rare]</li>\n</ul>\n\n<h2>Solution</h2>\n<h3>Quick Fix</h3>\n<p>[Immediate workaround if available]</p>\n\n<h3>Step-by-Step Resolution</h3>\n<ol>\n<li>[First step with clear instructions]</li>\n<li>[Second step]</li>\n<li>[Verification step]</li>\n</ol>\n\n<h3>Expected Outcome</h3>\n<p>[What customer should see after completing steps]</p>\n\n<h2>Prerequisites</h2>\n<ul>\n<li>[Required access levels]</li>\n<li>[Required tools or permissions]</li>\n</ul>\n\n<h2>Related Articles</h2>\n<p>[Links to related KB pages if applicable]</p>\n\n<hr />\n<p><em>AI-Generated based on {{ $json.frequency }} support cases</em></p>\n<p><em>Last Updated: {{ new Date().toISOString().split('T')[0] }}</em></p>\n\nProvide ONLY the HTML content (Confluence storage format), no markdown.",
    "options": {}
  },
  "id": "generate-kb-article",
  "name": "AI: Generate KB Article",
  "type": "@n8n/n8n-nodes-langchain.agent",
  "typeVersion": 1.7,
  "position": [1420, 300]
}
```

#### C. Generate Article Title

**Insert new AI Agent node:**

```json
{
  "parameters": {
    "text": "=Based on this category and subcategory, generate a clear, SEO-friendly title for a knowledge base article:\n\nCategory: {{ $json.category }}\nSubcategory: {{ $json.subcategory }}\nFrequency: {{ $json.frequency }} cases\n\nGuidelines:\n- Be specific and descriptive\n- Include the main issue/topic\n- 5-10 words\n- No jargon\n- Customer-facing language\n\nExamples:\n- 'How to Reset Password for SSO Users'\n- 'Resolving AUTH_001 Authentication Errors'\n- 'Updating Payment Method in Billing Portal'\n\nProvide ONLY the title text, nothing else.",
    "options": {}
  },
  "id": "generate-article-title",
  "name": "AI: Generate Title",
  "type": "@n8n/n8n-nodes-langchain.agent",
  "typeVersion": 1.7,
  "position": [1420, 500]
}
```

#### D. Create Confluence Page

**Insert new HTTP Request node:**

```json
{
  "parameters": {
    "method": "POST",
    "url": "https://YOUR-COMPANY.atlassian.net/wiki/rest/api/content",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpBasicAuth",
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={\n  \"type\": \"page\",\n  \"title\": \"{{ $json.article_title }}\",\n  \"space\": {\n    \"key\": \"SUPPORT\"\n  },\n  \"body\": {\n    \"storage\": {\n      \"value\": \"{{ $json.article_content }}\",\n      \"representation\": \"storage\"\n    }\n  },\n  \"status\": \"current\"\n}",
    "options": {
      "response": {
        "response": {
          "responseFormat": "json"
        }
      }
    }
  },
  "id": "create-confluence-page",
  "name": "Create Confluence Page",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [1640, 300],
  "credentials": {
    "httpBasicAuth": {
      "id": "YOUR_CONFLUENCE_CREDENTIAL_ID",
      "name": "Confluence API (Basic Auth)"
    }
  }
}
```

> **Note**: Uses Confluence REST API `/rest/api/content` endpoint with Basic Auth credentials.

#### E. Add Labels to Page

**Insert new HTTP Request node:**

```json
{
  "parameters": {
    "method": "POST",
    "url": "=https://YOUR-COMPANY.atlassian.net/wiki/rest/api/content/{{ $json.id }}/label",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpBasicAuth",
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "=[\n  {\n    \"prefix\": \"global\",\n    \"name\": \"ai-generated\"\n  },\n  {\n    \"prefix\": \"global\",\n    \"name\": \"category-{{ $json.category }}\"\n  },\n  {\n    \"prefix\": \"global\",\n    \"name\": \"priority-medium\"\n  }\n]",
    "options": {
      "response": {
        "response": {
          "responseFormat": "json"
        }
      }
    }
  },
  "id": "add-confluence-labels",
  "name": "Add Labels to Page",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [1860, 300],
  "credentials": {
    "httpBasicAuth": {
      "id": "YOUR_CONFLUENCE_CREDENTIAL_ID",
      "name": "Confluence API (Basic Auth)"
    }
  }
}
```

> **Note**: Uses Confluence REST API `/rest/api/content/{id}/label` endpoint to add labels.

#### F. Trigger Re-indexing

**Insert new HTTP Request node:**

```json
{
  "parameters": {
    "method": "POST",
    "url": "={{ $env.N8N_WEBHOOK_BASE_URL }}/webhook/confluence/reindex",
    "sendBody": true,
    "bodyParameters": {
      "parameters": [
        {
          "name": "page_ids",
          "value": "=[{{ $json.id }}]"
        }
      ]
    },
    "options": {}
  },
  "id": "trigger-reindex",
  "name": "Trigger KB Re-indexing",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [2080, 300]
}
```

#### G. Log New KB Page

**Insert new PostgreSQL node:**

```json
{
  "parameters": {
    "operation": "executeQuery",
    "query": "INSERT INTO kb_article_audit (\n  confluence_page_id,\n  title,\n  category,\n  subcategory,\n  source,\n  case_count,\n  created_by,\n  created_at\n)\nVALUES (\n  '{{ $json.id }}',\n  '{{ $json.article_title }}',\n  '{{ $json.category }}',\n  '{{ $json.subcategory }}',\n  'workflow-5-auto-generated',\n  {{ $json.frequency }},\n  'ai-agent',\n  NOW()\n);",
    "options": {}
  },
  "id": "log-kb-creation",
  "name": "Log KB Creation",
  "type": "n8n-nodes-base.postgres",
  "typeVersion": 2.6,
  "position": [2080, 500],
  "credentials": {
    "postgres": {
      "id": "YOUR_POSTGRES_CREDENTIAL_ID",
      "name": "PostgreSQL - Support DB"
    }
  }
}
```

### Node Connections for Workflow 5

Add these connections:

```
[Existing gap analysis]
    ↓
[Identify KB Gaps] (new)
    ↓
    ├─→ [AI: Generate KB Article]
    └─→ [AI: Generate Title]
         ↓
[Merge Data] (combine article + title)
    ↓
[Create Confluence Page]
    ↓
[Add Labels to Page]
    ↓
    ├─→ [Trigger KB Re-indexing]
    └─→ [Log KB Creation]
```

---

## 5. Database Schema Updates

**Add audit table for KB articles:**

```sql
CREATE TABLE IF NOT EXISTS kb_article_audit (
  id BIGSERIAL PRIMARY KEY,
  confluence_page_id TEXT NOT NULL,
  title TEXT NOT NULL,
  category TEXT,
  subcategory TEXT,
  source TEXT NOT NULL, -- 'manual', 'workflow-5-auto-generated', 'imported'
  case_count INTEGER DEFAULT 0,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_updated_at TIMESTAMPTZ,
  status TEXT DEFAULT 'active', -- 'active', 'archived', 'deprecated'
  quality_score FLOAT, -- 0-1, based on customer feedback
  usage_count INTEGER DEFAULT 0, -- how many times retrieved
  success_rate FLOAT -- resolution success when this article is used
);

CREATE INDEX idx_kb_audit_page_id ON kb_article_audit(confluence_page_id);
CREATE INDEX idx_kb_audit_category ON kb_article_audit(category);
CREATE INDEX idx_kb_audit_status ON kb_article_audit(status);
```

---

## 6. Environment Variables

**Add to n8n Settings > Environment Variables:**

```bash
# Confluence
CONFLUENCE_BASE_URL=https://your-company.atlassian.net
CONFLUENCE_SPACE_KEY=SUPPORT

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key

# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_EMBEDDING_MODEL=text-embedding-3-small

# n8n
N8N_WEBHOOK_BASE_URL=https://your-n8n-instance.com
```

---

## 7. Testing Checklist

### Test Confluence KB Indexer

```bash
# 1. Import workflow
# 2. Update all credentials
# 3. Run manually: "Execute Workflow"
# 4. Check Supabase:
SELECT COUNT(*) FROM confluence_kb;
SELECT page_id, title, char_length(content) FROM confluence_kb LIMIT 5;

# 5. Verify embeddings exist:
SELECT COUNT(*) FROM confluence_kb WHERE embedding IS NOT NULL;

# 6. Test vector search:
SELECT * FROM match_confluence_pages(
  (SELECT embedding FROM confluence_kb LIMIT 1),
  0.7,
  5
);
```

### Test Workflow 2 Enhancement

```bash
# Send test request with known issue
curl -X POST https://your-n8n.com/webhook/support/intake \
  -H "Content-Type: application/json" \
  -d '{
    "customer_email": "test@example.com",
    "description": "I cannot reset my password, getting AUTH_001 error",
    "product": "web-portal"
  }'

# Check n8n execution:
# 1. Verify "KB Vector Search" node returns results
# 2. Check similarity scores (should be >0.7)
# 3. Verify AI includes KB content in solution
# 4. Confirm response includes KB links
```

### Test Workflow 5 KB Creation

```bash
# 1. Create 3+ support cases with same novel issue
# 2. Wait for next Workflow 5 run (or trigger manually)
# 3. Check Confluence for new page
# 4. Verify page has correct labels
# 5. Check kb_article_audit table
# 6. Confirm page is indexed (check confluence_kb table)
# 7. Test that future similar issues retrieve the new page
```

---

## 8. Rollback Plan

If integration causes issues:

### Quick Rollback (Workflow 2)
1. Deactivate Confluence KB Indexer workflow
2. Workflow 2 still works with existing vector store
3. No code changes needed

### Full Rollback (Workflow 5)
1. Remove Confluence nodes from Workflow 5
2. Existing learning workflow continues without KB creation
3. Manual KB creation still possible

### Data Rollback
```sql
-- Remove indexed pages if needed
DELETE FROM confluence_kb WHERE last_indexed_at > 'YYYY-MM-DD';

-- Archive auto-generated articles
UPDATE kb_article_audit
SET status = 'archived'
WHERE source = 'workflow-5-auto-generated'
  AND created_at > 'YYYY-MM-DD';
```

---

## 9. Performance Optimization

### Indexer Performance
- Batch size: Process 100 pages at a time
- Embedding cost: ~$0.01 per 100 pages (text-embedding-3-small)
- Duration: ~5-10 minutes for 100 pages
- Schedule: Daily at 2 AM (low traffic time)

### Vector Search Performance
- Query time: 50-200ms for 5 results
- Cached embeddings: No API call needed
- Confluence API: Only if using Option B (live fetch)

### Workflow 5 Performance
- KB creation: Only when frequency >= 3 cases
- AI generation: ~10 seconds per article
- Confluence API: Rate limit ~5 requests/second

---

## 10. Monitoring & Alerts

**Add to Grafana dashboard:**

```sql
-- KB indexing success rate
SELECT
  DATE(last_indexed_at) as date,
  COUNT(*) as pages_indexed
FROM confluence_kb
WHERE last_indexed_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(last_indexed_at);

-- Vector search performance
SELECT
  DATE(searched_at) as date,
  AVG(similarity_score) as avg_similarity,
  COUNT(*) as total_searches
FROM kb_search_log
GROUP BY DATE(searched_at);

-- Auto-generated articles
SELECT
  DATE(created_at) as date,
  COUNT(*) as articles_created,
  AVG(case_count) as avg_cases_per_article
FROM kb_article_audit
WHERE source = 'workflow-5-auto-generated'
GROUP BY DATE(created_at);
```

**Slack alerts:**
- ⚠️ Indexing fails 2+ times in a row
- ⚠️ No KB results for >50% of searches
- ⚠️ Confluence API errors
- ⚠️ Vector search latency >2 seconds

---

## Summary

### What's Already Working ✅
- Workflow 2 has vector search for KB articles
- Supabase vector store configured
- OpenAI embeddings integrated

### What's New ✅
- Confluence KB Indexer workflow (CREATED)
- Daily automated indexing
- Full page content storage

### What Needs Minor Updates 🔧
- Workflow 2: Verify AI prompt includes KB context
- Workflow 5: Add Confluence page creation nodes
- Database: Add audit tables

### Estimated Implementation Time
- Import and configure indexer: 30 minutes
- Test and validate: 30 minutes
- Modify Workflow 5: 1-2 hours
- Total: **2-3 hours**

---

**Next Steps:**
1. Import `workflow-confluence-kb-indexer.json`
2. Update all credential IDs
3. Run initial index
4. Verify in Supabase
5. Test Workflow 2 (should work as-is)
6. Add Confluence nodes to Workflow 5
7. Monitor and optimize

---

*Last Updated: January 2026*
