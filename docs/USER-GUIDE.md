# CX-Catalyst - User Guide

A comprehensive guide for support staff and team leads using the AI-powered support system.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Understanding the Workflow](#understanding-the-workflow)
3. [Working with Cases](#working-with-cases)
4. [Human Review Process](#human-review-process)
5. [Knowledge Base](#knowledge-base)
6. [Slack Integration](#slack-integration)
7. [Reports and Metrics](#reports-and-metrics)
8. [Best Practices](#best-practices)
9. [FAQ](#faq)

---

## System Overview

The CX-Catalyst system uses AI to automate and accelerate support case resolution. It combines:

- **AI-Powered Triage** - Automatic classification and routing
- **Self-Service Resolution** - Automated solutions for common issues
- **Human-in-Loop Review** - Your expertise where it matters most
- **Continuous Learning** - System improves from every interaction

### Your Role

As a support team member, you'll:

1. Review AI-generated solutions for medium-confidence cases
2. Approve, edit, or reject proposed resolutions
3. Handle escalated complex cases
4. Contribute feedback that improves the AI

---

## Understanding the Workflow

### How Cases Flow Through the System

```
Customer Request
      │
      ▼
┌─────────────────┐
│  AI Triage      │ ← Classifies: category, priority, confidence
└────────┬────────┘
         │
         ▼
    ┌────┴────┐
    │ Routing │
    └────┬────┘
         │
    ┌────┼────┬────────────┐
    ▼    ▼    ▼            ▼
 Self-  Human  Collab-   Escalate
Service Review orative   to Expert
```

### Confidence Levels

The AI assigns a confidence score (0-100%) to each classification:

| Confidence | Routing | Your Action |
|------------|---------|-------------|
| 85-100% | Self-Service | None - auto-resolved |
| 60-84% | Collaborative | Review AI solution in Slack |
| Below 60% | Escalation | Manual investigation required |

### Case Categories

- **Configuration** - Settings, environment, integration issues
- **Usage** - How-to questions, feature usage
- **Setup** - Initial installation, onboarding
- **Defect** - Bug reports, unexpected behavior
- **Enhancement** - Feature requests, improvements
- **Other** - Uncategorized or mixed issues

### Priority Levels

| Priority | Criteria | Target Response |
|----------|----------|-----------------|
| Critical | System down, security, data loss | Immediate |
| High | Major function broken, VIP customer | 2 hours |
| Medium | Workaround exists, single customer | 4 hours |
| Low | Questions, cosmetic, feature requests | 24 hours |

---

## Working with Cases

### Case Lifecycle

1. **New** - Just received, awaiting triage
2. **Triaged** - AI classified, routing determined
3. **In Progress** - Being worked (self-service or human)
4. **Pending Review** - Awaiting human approval
5. **Resolved** - Solution delivered
6. **Closed** - Customer confirmed or timeout

### Viewing Case Details

Each case includes:

- **Case ID** - Unique identifier (UUID format)
- **Customer Info** - Name, email, account tier
- **Description** - Original issue reported
- **Classification** - Category, priority, confidence
- **History** - All interactions and status changes
- **AI Analysis** - Suggested solutions and reasoning

### Case Context

The AI gathers context before generating solutions:

- Customer's support history
- Account tier and configuration
- Product version and environment
- Similar resolved cases
- Relevant KB articles

---

## Human Review Process

### The Review Queue

Medium-confidence cases appear in the **#support-review** Slack channel.

#### Review Message Format

```
🎫 Case #abc123 - Review Needed

Customer: John Doe (Enterprise)
Priority: High
Category: Configuration

Issue: Cannot configure SSL certificates...

AI Suggested Solution:
1. Check certificate format...
2. Verify file permissions...
3. Restart the service...

Confidence: 72%
Sources: KB-001, KB-045

Actions:
✅ Approve | ✏️ Edit | ❌ Reject

Review within 2 hours: [link]
```

### Taking Action

#### Approve ✅

Click **Approve** when the AI solution is correct and complete.

- Solution sent to customer immediately
- Case marked as resolved
- AI learns this was a good response

#### Edit ✏️

Click **Edit** to modify the solution before sending.

1. Review opens in a form
2. Make your changes
3. Add comments explaining edits
4. Submit the revised solution

**Your edits train the AI** - it learns from corrections.

#### Reject ❌

Click **Reject** when the solution is wrong or insufficient.

1. Provide reason for rejection
2. Case escalates to senior engineer
3. AI flagged for review on this case type

### Review Timeout

Cases have a **2-hour review window**. After timeout:

- Case auto-escalates to senior queue
- Alert sent to team lead
- No penalty to you - just ensures nothing is missed

### Review Tips

1. **Read the full context** - Don't just skim the AI solution
2. **Check the sources** - Verify KB article references
3. **Consider the customer** - Enterprise tier needs extra care
4. **Note patterns** - Repeated edits on similar cases = training opportunity

---

## Knowledge Base

### How the KB Works

The knowledge base powers AI solutions through:

- **Vector Search** - Semantic similarity matching
- **Error Codes** - Direct lookup for known issues
- **Case History** - Similar resolved cases

### Finding KB Articles

Articles are stored in:
- **Supabase** - Vector embeddings for search
- **Confluence** - Human-readable format

### Contributing to the KB

Your approved and edited solutions become training data:

1. Approved solutions reinforce correct patterns
2. Edited solutions teach the AI better approaches
3. High-success articles get prioritized in search

### Suggesting New Articles

When you notice missing documentation:

1. Note the gap during case review
2. Add a comment: "KB_GAP: [topic needed]"
3. Daily learning workflow creates draft articles
4. Technical writer reviews and publishes

---

## Slack Integration

### Channels

| Channel | Purpose |
|---------|---------|
| #support-review | Case review queue |
| #support-alerts | Critical escalations |
| #support-metrics | Daily insights |
| #support-general | Team discussion |

### Notifications You'll Receive

- **New review request** - Case assigned to queue
- **Timeout warning** - 30 min before auto-escalate
- **Escalation alert** - Critical case needs attention
- **Daily summary** - Yesterday's metrics

### Slack Commands

While in #support-review:

- Reply in thread to add notes
- React with ✅ to quick-approve
- React with ❌ to quick-reject (opens reason dialog)

---

## Reports and Metrics

### Daily Dashboard

Available in Confluence and #support-metrics:

- **Cases Received** - Total volume
- **Resolution Rate** - % cases resolved
- **Self-Service Rate** - % automated
- **Avg Resolution Time** - By category
- **Satisfaction Score** - Customer ratings
- **Top Issues** - Most common problems

### Your Performance

Track your contributions:

- Cases reviewed
- Approval vs edit vs reject ratio
- Average review time
- Feedback provided

> **Note:** Metrics are for improvement, not punishment. Higher edit rates mean you're training the AI.

### Weekly Trends

Leadership report includes:

- Week-over-week comparisons
- Category breakdown changes
- Emerging issues
- Process improvement opportunities

---

## Best Practices

### Reviewing Cases

1. **Be thorough** - A minute of review saves hours of back-and-forth
2. **Use context** - Customer history reveals patterns
3. **Edit freely** - Your corrections improve the system
4. **Document reasoning** - Comments help others learn

### Writing Good Edits

When editing AI solutions:

- **Be specific** - Numbered steps work best
- **Explain why** - Not just what to do
- **Include verification** - How to confirm it worked
- **Add caveats** - Any risks or prerequisites

### Handling Escalations

For escalated cases:

1. Acknowledge receipt quickly
2. Set expectations on timeline
3. Document your investigation
4. Loop in specialists early if needed
5. Update the KB when resolved

### Improving the System

Help the AI learn:

- **Consistent classifications** - Use standard categories
- **Detailed rejections** - Explain why solutions failed
- **Flag patterns** - Note recurring issues
- **Suggest KB updates** - Fill documentation gaps

---

## FAQ

### General

**Q: Does the AI replace my job?**
A: No. The AI handles routine cases so you can focus on complex problems that need human expertise. Your role shifts from repetitive work to higher-value activities.

**Q: What if I disagree with the AI?**
A: Edit or reject. Your judgment takes priority. The system learns from your corrections.

**Q: How accurate is the AI?**
A: It achieves ~85% accuracy on well-documented issues. That's why human review exists for medium-confidence cases.

### Reviews

**Q: What if I'm not sure about a solution?**
A: When in doubt, reject and let a senior engineer handle it. Better safe than sorry.

**Q: Can I see why the AI suggested something?**
A: Yes. Each solution includes "Sources" and "Reasoning" explaining the logic.

**Q: What happens to rejected cases?**
A: They escalate to senior queue and are flagged for AI review. The case still gets resolved - just by a human.

### Technical

**Q: How fast should the system respond?**
A: Triage takes 2-5 seconds. Full self-service resolution: 30-60 seconds. You'll see cases in Slack within 1 minute of submission.

**Q: What if the system is down?**
A: Cases queue for processing. Critical issues fall through to email backup. You'll be notified of any outages.

**Q: Can customers see the AI is responding?**
A: They see a human-friendly response. Behind the scenes, it's AI + human review. We don't hide this - we just don't highlight it unnecessarily.

---

## Getting Help

### System Issues

Contact your admin for:
- Login problems
- Missing permissions
- Configuration changes
- Integration issues

### Process Questions

Ask in #support-general or contact your team lead.

### Training

New team members should:
1. Read this guide
2. Shadow reviews for 1 day
3. Handle supervised reviews for 1 week
4. Graduate to independent review

---

*User Guide v1.0 - January 2026*
