# Confluence Integration Workflow Diagrams

Visual reference for how Confluence integrates with each workflow.

---

## Complete System Architecture with Confluence

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CONFLUENCE CLOUD                             │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Support Knowledge Base Space                                │    │
│  │                                                             │    │
│  │  • Authentication & Access (15 pages)                       │    │
│  │  • Billing & Subscriptions (12 pages)                       │    │
│  │  • Product Configuration (25 pages)                         │    │
│  │  • Troubleshooting (30 pages)                               │    │
│  │  • Known Issues & Bugs (10 pages)                           │    │
│  │  • Internal Runbooks (8 pages)                              │    │
│  │                                                             │    │
│  │  Total: ~100 pages                                          │    │
│  └────────────────────────────────────────────────────────────┘    │
│                              ▲                                       │
│                              │ API (Read/Write)                      │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │   n8n WORKFLOWS     │
                    └─────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
   ┌────▼────┐           ┌────▼────┐           ┌────▼────┐
   │ WF: KB  │           │   WF2   │           │   WF5   │
   │ Indexer │           │ Self-   │           │ Learning│
   │         │           │ Service │           │         │
   └────┬────┘           └────┬────┘           └────┬────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE (PostgreSQL)                     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │ confluence_kb Table                                 │    │
│  │                                                     │    │
│  │  Columns:                                           │    │
│  │  - page_id (TEXT)                                   │    │
│  │  - title (TEXT)                                     │    │
│  │  - content (TEXT)                                   │    │
│  │  - embedding (VECTOR 1536) ← OpenAI embeddings     │    │
│  │  - url (TEXT)                                       │    │
│  │  - metadata (JSONB)                                 │    │
│  │  - updated_at (TIMESTAMPTZ)                         │    │
│  │                                                     │    │
│  │  Indexes:                                           │    │
│  │  - ivfflat on embedding (vector similarity)         │    │
│  │  - btree on page_id (lookups)                       │    │
│  │                                                     │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Workflow: Confluence KB Indexer

**Purpose**: Index all Confluence pages into vector database for semantic search

**Trigger**: Manual or Scheduled (Daily at 2 AM)

```
START
  │
  ├─ [1] Get Confluence Space Info
  │     Input: Space key "SUPPORT"
  │     Output: Space metadata
  │
  ├─ [2] Get All Pages in Space
  │     API: GET /wiki/rest/api/content
  │     Params: space=SUPPORT, limit=100, expand=body.storage
  │     Output: Array of pages (id, title, content, url)
  │
  ├─ [3] Loop: For Each Page
  │     │
  │     ├─ [3a] Extract & Clean Content
  │     │     - Remove HTML tags
  │     │     - Strip formatting
  │     │     - Truncate to 32K chars
  │     │     Output: Clean text
  │     │
  │     ├─ [3b] Generate Embedding
  │     │     API: OpenAI text-embedding-3-small
  │     │     Input: Title + Content
  │     │     Output: Vector[1536]
  │     │     Cost: ~$0.0001 per page
  │     │
  │     └─ [3c] Upsert to Supabase
  │           SQL: INSERT ... ON CONFLICT UPDATE
  │           Table: confluence_kb
  │           Updates: embedding, content, updated_at
  │
  ├─ [4] Log Results
  │     - Pages indexed: 100
  │     - Time taken: 5 min
  │     - Errors: 0
  │
END
```

**Example Execution:**
- **Input**: 100 Confluence pages
- **Processing**: 5-10 minutes
- **Cost**: ~$0.01 (OpenAI embeddings)
- **Output**: 100 vector embeddings in Supabase

---

## Workflow 2: Self-Service with Confluence KB

**Purpose**: Resolve customer issues using Confluence knowledge base

**Enhanced Flow with KB Integration:**

```
START: Customer Issue Received
  │
  ├─ [1] Classify Issue
  │     AI determines: category, priority, confidence
  │     Output: classification metadata
  │
  ├─ [2] Generate Query Embedding
  │     │
  │     ├─ Input: Customer description
  │     │   "I can't reset my password. Error: AUTH_001"
  │     │
  │     ├─ Process: OpenAI embedding
  │     │   Model: text-embedding-3-small
  │     │
  │     └─ Output: Query vector[1536]
  │
  ├─ [3] Search Vector Database
  │     │
  │     ├─ Function: match_confluence_pages()
  │     │   Parameters:
  │     │   - query_embedding: [vector from step 2]
  │     │   - match_threshold: 0.7
  │     │   - match_count: 5
  │     │
  │     └─ Output: Top 5 similar pages
  │         [
  │           {
  │             page_id: "12345",
  │             title: "Password Reset for SSO Users",
  │             similarity: 0.89,
  │             url: "https://..."
  │           },
  │           {
  │             page_id: "12346",
  │             title: "AUTH_001 Error Code Guide",
  │             similarity: 0.85,
  │             url: "https://..."
  │           },
  │           ...
  │         ]
  │
  ├─ [4] Fetch Full Confluence Content
  │     │
  │     ├─ For each page_id from step 3:
  │     │   API: GET /wiki/rest/api/content/{page_id}
  │     │   Expand: body.storage
  │     │
  │     └─ Output: Full page content (HTML)
  │
  ├─ [5] AI Generate Solution
  │     │
  │     ├─ Prompt includes:
  │     │   • Customer issue description
  │     │   • Classification metadata
  │     │   • Top 5 Confluence pages (full content)
  │     │   • Similarity scores
  │     │
  │     ├─ AI Instructions:
  │     │   "Based on the customer's issue and the KB articles,
  │     │    synthesize a personalized solution. Include:
  │     │    1. Clear explanation
  │     │    2. Step-by-step fix
  │     │    3. Links to relevant KB articles
  │     │    4. Prerequisites"
  │     │
  │     └─ Output: Custom solution text
  │
  ├─ [6] Format Response
  │     │
  │     ├─ Add metadata:
  │     │   - KB articles used: [links]
  │     │   - Confidence: 0.89
  │     │   - Source: "AI + Confluence KB"
  │     │
  │     └─ Output: Formatted customer email
  │
  ├─ [7] Log to Database
  │     Table: case_interactions
  │     Fields:
  │     - case_id
  │     - kb_pages_retrieved: ["12345", "12346", ...]
  │     - best_match_score: 0.89
  │     - kb_pages_used_in_solution: ["12345"]
  │
  └─ [8] Send to Customer
        Email with solution + KB links
│
END
```

**Example with Confluence:**

**Input:**
```json
{
  "customer": "john@example.com",
  "description": "Getting AUTH_001 when trying to reset password",
  "product": "web-portal"
}
```

**Vector Search Results:**
```json
[
  {
    "page_id": "98765",
    "title": "AUTH_001: Authentication Service Error",
    "similarity": 0.92,
    "url": "https://kb.company.com/auth-001",
    "snippet": "This error occurs when the authentication service..."
  },
  {
    "page_id": "98766",
    "title": "How to Reset Password for Web Portal Users",
    "similarity": 0.87,
    "url": "https://kb.company.com/password-reset",
    "snippet": "Follow these steps to reset your password..."
  }
]
```

**AI-Generated Solution (with KB context):**
```
Hi John,

I understand you're getting an AUTH_001 error when trying to reset
your password. This error typically occurs when the authentication
service is temporarily unavailable or your session has expired.

Here's how to resolve this:

1. Clear your browser cache and cookies
2. Try the password reset link again from a fresh browser window
3. If the error persists, wait 10 minutes and retry (the service
   may be experiencing temporary issues)

For detailed instructions, see:
- AUTH_001 Error Code Guide: https://kb.company.com/auth-001
- Password Reset Process: https://kb.company.com/password-reset

If the issue continues after following these steps, please reply
and we'll escalate to our authentication team.

Best regards,
Support Team
```

**Metrics Logged:**
- `kb_match_score`: 0.92
- `kb_pages_retrieved`: 2
- `solution_generated_with_kb`: true
- `estimated_accuracy`: high

---

## Workflow 5: Continuous Learning with Confluence Updates

**Purpose**: Analyze patterns and automatically update Confluence KB

**Flow:**

```
SCHEDULED: Daily at 3 AM
  │
  ├─ [1] Analyze Past 24 Hours
  │     │
  │     ├─ Query: Get resolved cases
  │     │   WHERE resolved_at > NOW() - INTERVAL '24 hours'
  │     │   AND resolution_successful = true
  │     │
  │     └─ Output: 150 resolved cases
  │
  ├─ [2] Identify Knowledge Gaps
  │     │
  │     ├─ Filter: Cases WITHOUT good KB matches
  │     │   WHERE kb_match_score < 0.7
  │     │   OR kb_pages_retrieved = 0
  │     │
  │     ├─ Group by category and issue pattern
  │     │
  │     └─ Output: Knowledge gaps
  │         [
  │           {
  │             category: "authentication",
  │             issue_pattern: "2FA token expired",
  │             frequency: 12,
  │             sample_cases: [...]
  │           },
  │           ...
  │         ]
  │
  ├─ [3] For Each Knowledge Gap:
  │     │
  │     ├─ [3a] Check if Page Already Exists
  │     │     Search Confluence for similar title
  │     │     If exists: Go to step 3c (update)
  │     │     If not: Go to step 3b (create)
  │     │
  │     ├─ [3b] Create New KB Article
  │     │     │
  │     │     ├─ AI Generate Content
  │     │     │   Prompt: "Based on these 12 resolved cases about
  │     │     │            '2FA token expired', create a KB article
  │     │     │            using our standard template..."
  │     │     │   Output: Confluence-formatted HTML
  │     │     │
  │     │     ├─ AI Generate Title
  │     │     │   Output: "Resolving Expired 2FA Tokens"
  │     │     │
  │     │     ├─ Create Page in Confluence
  │     │     │   API: POST /wiki/rest/api/content
  │     │     │   Space: SUPPORT
  │     │     │   Parent: "Authentication & Access"
  │     │     │   Body: [AI-generated content]
  │     │     │   Labels: ["ai-generated", "category:authentication"]
  │     │     │
  │     │     └─ Output: New page_id
  │     │
  │     └─ [3c] Update Existing KB Article
  │           │
  │           ├─ Fetch current page content
  │           │   API: GET /wiki/rest/api/content/{page_id}
  │           │
  │           ├─ AI Suggest Improvements
  │           │   Input: Current content + new case resolutions
  │           │   Output: Updated content with additions
  │           │
  │           ├─ Update Page
  │           │   API: PUT /wiki/rest/api/content/{page_id}
  │           │   Version: current + 1
  │           │   Body: [Updated content]
  │           │
  │           └─ Add Comment
  │                 "Updated based on 12 recent support cases"
  │
  ├─ [4] Re-Index Modified Pages
  │     │
  │     ├─ Trigger: Confluence KB Indexer workflow
  │     │   Input: List of modified page_ids
  │     │
  │     └─ Output: Updated embeddings in Supabase
  │
  ├─ [5] Generate Report
  │     │
  │     ├─ Summary:
  │     │   - New KB articles created: 3
  │     │   - Existing articles updated: 5
  │     │   - Knowledge gaps addressed: 8
  │     │   - Total pages now: 108
  │     │
  │     └─ Send to Slack #support-updates
  │
END
```

**Example Output:**

**New Page Created:**
```
Title: "Resolving Expired 2FA Tokens"
Space: SUPPORT
Parent: Authentication & Access
URL: https://company.atlassian.net/wiki/spaces/SUPPORT/pages/123456

Content:
## Problem Statement
Users are unable to authenticate when their 2FA token has expired...

## Solution
1. Navigate to Settings > Security
2. Click "Reset 2FA Device"
3. Scan the new QR code...

## Affected Users
- All users with 2FA enabled
- Typically occurs after 30 days of inactivity

## Related Articles
- [Two-Factor Authentication Setup]
- [Security Best Practices]

---
*AI-Generated based on 12 support cases*
*Last Updated: 2026-01-19*
```

**Slack Notification:**
```
📚 Daily KB Update Report - January 19, 2026

✅ 3 new articles created
📝 5 existing articles updated
🔍 8 knowledge gaps addressed

Top new articles:
1. "Resolving Expired 2FA Tokens" (12 cases)
2. "API Rate Limit Error Handling" (8 cases)
3. "Email Notification Delays" (6 cases)

View all updates: [Confluence Recent Changes]
```

---

## Data Flow Summary

### Daily Operations

```
Morning (3 AM):
  Workflow 5 runs
    ↓
  Analyzes yesterday's cases
    ↓
  Creates/updates Confluence pages
    ↓
  Re-indexes new/modified pages
    ↓
  Vector embeddings updated
    ↓
  Better search results today!

Throughout Day:
  Customer requests arrive
    ↓
  Workflow 2 searches KB
    ↓
  Retrieves latest Confluence content
    ↓
  AI generates solutions
    ↓
  Links to KB articles provided
    ↓
  Resolution logged
    ↓
  Data feeds back to Workflow 5
```

### Continuous Improvement Loop

```
┌─────────────────────────────────────────────┐
│                                             │
│  1. Customer Issue                          │
│         ↓                                   │
│  2. Search Confluence KB (WF2)              │
│         ↓                                   │
│  3. Generate Solution                       │
│         ↓                                   │
│  4. Customer Resolution                     │
│         ↓                                   │
│  5. Log Outcome + KB Usage                  │
│         ↓                                   │
│  6. Nightly Analysis (WF5)                  │
│         ↓                                   │
│  7. Identify Gaps                           │
│         ↓                                   │
│  8. Update Confluence ──────────────────┐   │
│         ↓                               │   │
│  9. Re-index Pages                      │   │
│         ↓                               │   │
│ 10. Better KB Search ←──────────────────┘   │
│         ↓                                   │
│    (Back to step 1)                         │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Performance Metrics

### Expected Search Performance

- **Vector search latency**: 50-200ms
- **Confluence API fetch**: 100-500ms per page
- **Total KB retrieval**: <2 seconds for 5 pages
- **AI generation**: 3-5 seconds
- **End-to-end resolution**: <10 seconds

### Expected Costs (per 1000 requests)

- **OpenAI embeddings** (search queries): $0.10
- **Supabase queries**: Free (under 500K/month)
- **Confluence API**: Free (rate limited)
- **Claude AI** (solution generation): $3-5
- **Total**: ~$3-5 per 1000 support requests

### Expected Accuracy Improvements

**Without Confluence KB:**
- Self-service success rate: 40-50%
- Generic AI responses
- No source citations
- Customer satisfaction: 3.2/5

**With Confluence KB:**
- Self-service success rate: 75-85%
- Contextual, accurate responses
- KB article citations
- Customer satisfaction: 4.3/5

---

## Maintenance Schedule

### Daily (Automated)
- 2:00 AM: Re-index Confluence pages (all pages)
- 3:00 AM: Analyze gaps and create/update pages (WF5)
- 4:00 AM: Generate daily KB report

### Weekly (Manual)
- Monday: Review top 20 KB articles for accuracy
- Wednesday: Check for outdated content (>90 days)
- Friday: Review KB coverage gaps

### Monthly (Manual)
- Archive deprecated pages
- Consolidate duplicate articles
- Update screenshots and examples
- Quality audit of AI-generated pages

---

*For detailed implementation, see [CONFLUENCE-INTEGRATION.md](CONFLUENCE-INTEGRATION.md)*
