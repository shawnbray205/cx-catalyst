# CX-Catalyst Workflow Testing Notes

Documentation of issues discovered and fixes applied during workflow testing (January 2026).

---

## Summary

All 5 workflows have been tested and are operational:

| Workflow | Status | Key Fixes Applied |
|----------|--------|-------------------|
| WF1: Smart Intake & Triage | ✅ Working | None required |
| WF2: Self-Service Resolution | ✅ Working | None required |
| WF3: Proactive Health Monitoring | ✅ Working | Added Merge node for parallel queries |
| WF4: Collaborative Support | ✅ Working | None required |
| WF5: Continuous Learning | ✅ Working | Multiple fixes (see below) |

---

## Workflow 3: Proactive Health Monitoring

### Issue: Code Node Executing Multiple Times

**Symptom:** The "Correlate Data" Code node was receiving data from only one query at a time instead of all parallel queries together.

**Root Cause:** Four parallel PostgreSQL queries connected directly to a Code node. n8n executes the Code node once per input connection, not once with all inputs combined.

**Fix:** Added a 4-input Merge node between the parallel queries and the Code node.

**Pattern:**
```
[Check System Health] ───┐
[Check Error Spikes]  ───┼──→ [Merge] → [Correlate Data]
[Check Affected Users] ──┤
[Get Recent Alerts]   ───┘
```

**Code Update:** Changed Code node to use `$input.all()`:
```javascript
const allItems = $input.all().map(item => item.json);
// Filter by item type based on unique fields
const healthMetrics = allItems.filter(item => item.metric_name);
const errorSpikes = allItems.filter(item => item.error_code);
// etc.
```

---

## Workflow 5: Continuous Learning & Improvement

Multiple issues were discovered and fixed in this workflow.

### Issue 1: Parallel Queries Need Merge Node

**Same pattern as WF3** - Four parallel data queries needed a Merge node before "Merge Daily Data" Code node.

### Issue 2: SQL GROUP BY Error

**Symptom:** `column "af.created_at" must appear in GROUP BY clause`

**Root Cause:** Using `ORDER BY af.created_at` without including it in GROUP BY.

**Fix:** Changed to `MAX(af.created_at) as latest_feedback` and `ORDER BY latest_feedback DESC`

### Issue 3: Environment Variable Access Denied

**Symptom:** `$env.LEADERSHIP_EMAIL` not accessible in n8n Cloud.

**Fix:** Hardcoded email address in Send Report Email node. (Consider using n8n Variables for production.)

### Issue 4: Email Showing Raw Markdown

**Symptom:** Gmail node sent markdown text instead of formatted HTML.

**Fix:** Added "Format Email Report" Code node to convert markdown report to HTML with inline styles.

### Issue 5: Split In Batches Wrong Output Connected

**Symptom:** Loop Articles and Loop Bugs nodes had "done" output connected to processing nodes instead of "loop" output.

**Root Cause:** Misunderstanding of Split In Batches outputs:
- Output 0 (done): Fires when loop completes
- Output 1 (loop): Fires for each batch iteration

**Fix:** Connected Output 1 (loop) to Article Generator Agent and Create Jira Bug nodes.

### Issue 6: Prepare Confluence Content Missing Article Metadata

**Symptom:** `Cannot read properties of undefined (reading 'title')`

**Root Cause:** After Article Generator Agent transforms the input, the original `article_to_generate` data is lost in `$input.item.json`.

**Fix:** Reference the Loop Articles node directly:
```javascript
const articleMeta = $('Loop Articles').first().json.article_to_generate;
```

### Issue 7: Confluence Space Not Found

**Symptom:** `Space does not exist` for space key "SUPPORT"

**Root Cause:** The Confluence space key was incorrect.

**Fix:** Changed space key from "SUPPORT" to "PKB" (Projects Knowledge Base).

### Issue 8: JSON Parameter Invalid

**Symptom:** `JSON parameter needs to be valid JSON` in Create Confluence Page HTTP Request.

**Root Cause:** Article content containing quotes and newlines broke JSON structure.

**Fix:** Pre-escape content in Prepare Confluence Content Code node:
```javascript
const jsonSafeContent = cleanContent
  .replace(/\\/g, '\\\\')
  .replace(/"/g, '\\"')
  .replace(/\n/g, '\\n')
  .replace(/\r/g, '\\r')
  .replace(/\t/g, '\\t');
```

Also removed `=` prefix from HTTP Request JSON body.

### Issue 9: Log to PostgreSQL Column Not Found

**Symptom:** `column "confluence_url" does not exist`

**Root Cause:** SQL query referenced a column that doesn't exist in kb_articles table.

**Fix:** Removed `confluence_url` from INSERT statement; only `confluence_page_id` exists.

### Issue 10: Confluence Page ID Undefined in SQL

**Symptom:** `confluence_page_id` inserted as 'undefined'

**Root Cause:** Add Labels to Page response doesn't include page ID; it's only in Create Confluence Page response.

**Fix:** Reference Create Confluence Page node directly:
```javascript
'{{ $('Create Confluence Page').item.json.id }}'
```

### Issue 11: Jira Bug Ticket Format Issue

**Symptom:** Jira tickets created with raw JSON expressions instead of values.

**Root Cause:** Create Jira Bug node not receiving properly formatted data from Loop Bugs.

**Fix:** Added "Format Bug Ticket" Code node between Loop Bugs and Create Jira Bug to properly extract and format bug data.

---

## Backlog Items Created

| Ticket | Title | Description |
|--------|-------|-------------|
| DEV-18 | KB Vector Indexing Integration | Implement webhook to trigger vector re-indexing when new KB articles are created in Confluence |
| DEV-19 | Confluence Page Upsert | Check for existing pages before creating; update instead of failing on duplicates |

---

## Key Lessons Learned

### 1. Split In Batches Outputs
Always connect the **loop output (index 1)** to processing nodes, not the done output (index 0).

### 2. Parallel Queries Need Merge
When multiple queries feed into a single Code node, add a Merge node first and use `$input.all()`.

### 3. JSON Escaping for HTTP Requests
Pre-escape content in a Code node before using in HTTP Request JSON bodies.

### 4. SQL Parameterization
Use parameterized queries (`$1, $2, $3...`) instead of inline expressions to avoid escaping issues.

### 5. Upstream Node References
After data transformations, use `$('NodeName').first().json` to access data from specific upstream nodes.

### 6. Test All Paths
Conditional branches (IF nodes) may have untested paths. Verify each branch works independently.

---

## Testing Checklist for Future Workflows

- [ ] Verify Split In Batches loop vs done outputs
- [ ] Add Merge node before Code nodes receiving parallel inputs
- [ ] Test JSON escaping for HTTP Request bodies
- [ ] Verify SQL column names match actual schema
- [ ] Check upstream node references after transformations
- [ ] Test all conditional branches (true and false paths)
- [ ] Verify Confluence/Jira space/project keys exist
- [ ] Test with real data to catch formatting issues

---

*Last Updated: January 2026*
