# Confluence Integration Setup Checklist

Quick reference checklist for implementing Confluence knowledge base integration.

---

## 📋 Pre-Implementation Checklist

### Access & Credentials
- [ ] Confluence Cloud or Data Center account
- [ ] Admin access to create spaces
- [ ] API token generated
- [ ] n8n Confluence credential configured
- [ ] Supabase account created
- [ ] OpenAI API key obtained

### Infrastructure
- [ ] PostgreSQL database with pgvector extension
- [ ] Supabase project created
- [ ] Vector table `confluence_kb` created
- [ ] Search function `match_confluence_pages()` created
- [ ] n8n instance running (v1.0+)

---

## 📚 Phase 1: Confluence Setup (Day 1)

### Create Knowledge Base Space
- [ ] Create new Confluence space (Space Key: `SUPPORT`)
- [ ] Set up space permissions (n8n service account: read/write)
- [ ] Create page hierarchy structure
  - [ ] Authentication & Access
  - [ ] Billing & Subscriptions
  - [ ] Product Configuration
  - [ ] Troubleshooting
  - [ ] Known Issues & Bugs
  - [ ] Internal Runbooks

### Create Page Templates
- [ ] Solution Article template
- [ ] Runbook template
- [ ] Troubleshooting Guide template
- [ ] Error Code Reference template

### Establish Labeling System
- [ ] Product labels (`product:*`)
- [ ] Category labels (`category:*`)
- [ ] Priority labels (`priority:*`)
- [ ] Status labels (`status:*`)

---

## 📝 Phase 2: Content Creation (Week 1)

### Audit Existing Knowledge
- [ ] Review past support tickets (top 50 by frequency)
- [ ] Gather internal documentation
- [ ] Collect product documentation
- [ ] Identify team tribal knowledge

### Create Core Articles (Target: 20-50)
- [ ] Top 10 most common issues
- [ ] Top 5 critical procedures
- [ ] Error code reference pages
- [ ] Product setup guides
- [ ] Integration documentation

### Quality Checks
- [ ] All pages follow template structure
- [ ] Clear, descriptive titles
- [ ] Proper labeling applied
- [ ] Screenshots and examples included
- [ ] Internal links established
- [ ] Reviewed by subject matter experts

---

## 🔧 Phase 3: Technical Implementation (Week 1-2)

### Create Confluence KB Indexer Workflow
- [ ] Import workflow template (or create from scratch)
- [ ] Configure Confluence node (Get Pages)
- [ ] Configure content cleaning (Code node)
- [ ] Configure OpenAI embedding (OpenAI node)
- [ ] Configure Supabase upsert (Supabase node)
- [ ] Test with 5-10 pages
- [ ] Run full index (all pages)
- [ ] Verify in Supabase: `SELECT COUNT(*) FROM confluence_kb;`

### Schedule Automatic Re-indexing
- [ ] Set schedule: Daily at 2 AM
- [ ] Add error handling
- [ ] Configure Slack notifications for failures
- [ ] Test scheduled run

### Modify Workflow 2: Self-Service Resolution
- [ ] Add "Generate Query Embedding" node after classification
- [ ] Add "Search Vector DB" node (Supabase)
- [ ] Add "Fetch Confluence Pages" node
- [ ] Update AI agent prompt to include KB context
- [ ] Update response format to include KB links
- [ ] Add KB metrics logging

### Test End-to-End
- [ ] Submit test support request
- [ ] Verify KB pages retrieved
- [ ] Check similarity scores (should be >0.7)
- [ ] Verify AI uses KB content in solution
- [ ] Confirm KB links in response
- [ ] Check logs for KB metrics

---

## 🔄 Phase 4: Continuous Learning Setup (Week 2-3)

### Modify Workflow 5: Continuous Learning
- [ ] Add knowledge gap analysis logic
- [ ] Add "Check Existing Pages" node
- [ ] Add "AI Generate KB Article" node
- [ ] Add "Create Confluence Page" node
- [ ] Add "Update Existing Page" node
- [ ] Add "Trigger Re-indexing" logic
- [ ] Add reporting to Slack

### Test KB Updates
- [ ] Manually run Workflow 5
- [ ] Verify gaps identified
- [ ] Check new pages created
- [ ] Verify pages re-indexed
- [ ] Confirm improvements in subsequent searches

### Schedule Daily Run
- [ ] Set schedule: Daily at 3 AM (after indexing)
- [ ] Configure error notifications
- [ ] Set up daily report delivery

---

## 📊 Phase 5: Monitoring & Optimization (Ongoing)

### Set Up Metrics Tracking
- [ ] KB search hit rate
- [ ] Average similarity score
- [ ] Resolution success rate (with KB vs without)
- [ ] Most-retrieved pages
- [ ] Pages never retrieved
- [ ] Search queries with no results

### Configure Alerts
- [ ] Alert if indexing fails
- [ ] Alert if search latency >2s
- [ ] Alert if KB match rate <50%
- [ ] Alert if new pages fail to create

### Create Dashboard
- [ ] Add KB metrics to Grafana
- [ ] Show top 20 pages by usage
- [ ] Display KB coverage by category
- [ ] Track KB growth over time

---

## ✅ Verification Tests

### Test 1: Basic Search
```bash
# Search for a known issue
curl -X POST https://your-n8n.com/webhook/support/intake \
  -H "Content-Type: application/json" \
  -d '{
    "customer_email": "test@example.com",
    "description": "I cant reset my password",
    "product": "web-portal"
  }'

# Expected: KB pages retrieved with similarity >0.7
# Expected: Response includes KB article links
```

### Test 2: No Match Scenario
```bash
# Search for completely novel issue
curl -X POST https://your-n8n.com/webhook/support/intake \
  -H "Content-Type: application/json" \
  -d '{
    "customer_email": "test@example.com",
    "description": "My quantum flux capacitor is malfunctioning",
    "product": "web-portal"
  }'

# Expected: KB match score <0.6
# Expected: Escalation to human support
```

### Test 3: Automatic KB Creation
```bash
# Create 5+ support cases for same novel issue
# Wait for next Workflow 5 run (3 AM next day)
# Check Confluence for new page created
# Verify page is indexed
# Test that future similar issues retrieve the new page
```

---

## 📈 Success Criteria

### Week 1
- [ ] 20-50 KB articles created
- [ ] All articles indexed successfully
- [ ] Vector search returns results for common issues
- [ ] Workflow 2 includes KB context in solutions

### Week 2
- [ ] Self-service resolution rate >60% (was <50%)
- [ ] Average KB match score >0.75
- [ ] Resolution time <5 minutes (was >24 hours)
- [ ] Customer satisfaction improvement visible

### Month 1
- [ ] Self-service resolution rate >75%
- [ ] KB coverage for top 50 issues: 100%
- [ ] 5+ new KB articles auto-created by Workflow 5
- [ ] Zero KB search failures

### Month 3
- [ ] Self-service resolution rate >85%
- [ ] 100+ KB articles total
- [ ] 10+ articles updated by AI based on new cases
- [ ] Support team workload reduced by 50%

---

## 🚨 Common Issues & Solutions

### Issue: No KB Results Returned
**Check:**
1. Are pages indexed? `SELECT COUNT(*) FROM confluence_kb;`
2. Are embeddings generated? `SELECT COUNT(*) FROM confluence_kb WHERE embedding IS NOT NULL;`
3. Is threshold too high? Try lowering to 0.6
4. Is search working? Test `match_confluence_pages()` directly

**Solution:** Re-run indexer, check OpenAI API quota

### Issue: Low Similarity Scores
**Check:**
1. Is page content relevant?
2. Is title descriptive?
3. Are search terms present in content?

**Solution:** Improve KB content, add more context, include synonyms

### Issue: Indexing Takes Too Long
**Check:**
1. How many pages? (>200 = slow)
2. API rate limits hit?
3. Network latency?

**Solution:** Batch processing, use faster embedding model, parallel indexing

### Issue: AI Ignores KB Content
**Check:**
1. Is KB content in prompt?
2. Is prompt too long? (>100K tokens)
3. Is KB content truncated?

**Solution:** Ensure full pages passed to AI, increase context window, prioritize most relevant pages

---

## 📚 Resources

- **[Full Integration Guide](docs/CONFLUENCE-INTEGRATION.md)** - Detailed setup instructions
- **[Workflow Diagrams](docs/CONFLUENCE-WORKFLOW-DIAGRAM.md)** - Visual reference
- **[Quick Start](docs/QUICK-START.md)** - 30-minute setup
- **[Admin Guide](docs/ADMIN-GUIDE.md)** - System administration

---

## 🎯 Next Steps After Completion

1. **Train the Team**
   - Show support staff how KB works
   - Demonstrate how to create quality articles
   - Explain AI synthesis process

2. **Monitor Performance**
   - Review metrics weekly
   - Identify low-performing articles
   - Track coverage gaps

3. **Iterate and Improve**
   - Expand KB coverage
   - Refine categorization
   - Optimize search parameters
   - Update templates based on feedback

4. **Scale Up**
   - Add more product documentation
   - Integrate additional knowledge sources
   - Consider multi-language support
   - Explore additional AI models

---

**Estimated Total Setup Time:** 2-3 weeks
**Estimated Effort:** 40-60 hours (full team)
**Expected ROI:** 70% reduction in manual support workload within 3 months

---

*Last Updated: January 2026*
