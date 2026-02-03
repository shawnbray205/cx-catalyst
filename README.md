# AI-Powered CX-Catalyst

An intelligent, automated customer support system built with n8n workflows and Claude AI that transforms reactive support into a proactive, scalable operation.

## Overview

This system uses AI to automatically classify, route, and resolve customer support requests with minimal human intervention. It combines smart triage, self-service resolution, proactive issue detection, and continuous learning to deliver faster resolutions while reducing support team workload.

### Key Features

- **Smart Intake & Triage** - Automatically classifies and prioritizes incoming support requests
- **Self-Service Resolution** - AI-generated solutions for common issues with 85%+ accuracy
- **100+ KB Articles** - Comprehensive Confluence knowledge base covering Enterprise, SMB, and Small Business tiers
- **Semantic Search** - Vector-powered KB retrieval using OpenAI embeddings and pgvector
- **Proactive Detection** - Monitors systems and prevents issues before customers report them
- **Human-in-Loop** - Expert review for complex cases with AI assistance
- **Continuous Learning** - Daily analysis improves accuracy and identifies patterns
- **Full Observability** - Grafana dashboard for monitoring metrics and token usage

## Quick Start

Get up and running in under 30 minutes. See the [Quick Start Guide](docs/QUICK-START.md) for detailed instructions.

**⚠️ Important**: For optimal performance, Confluence knowledge base integration is essential. Follow the [Confluence Setup Checklist](CONFLUENCE-SETUP-CHECKLIST.md) after initial setup.

```bash
# 1. Set up PostgreSQL database
psql -h your-db-host -U postgres -d postgres -f schema.sql

# 2. Import workflows to n8n
# Import files from n8n-workflows/ folder in n8n UI

# 3. Configure credentials in n8n
# PostgreSQL, Anthropic API, OpenAI API, Slack, etc.

# 4. Test the intake webhook
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

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Customer Request                             │
│                    (Email, Slack, API)                           │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│              Workflow 1: Smart Intake & Triage                   │
│  • AI Classification (category, priority, sentiment)             │
│  • Confidence Scoring                                            │
│  • Intelligent Routing                                           │
└─────────┬───────────────────────┬──────────────────┬────────────┘
          ↓                       ↓                  ↓
    High Confidence         Med Confidence     Low Confidence
    Simple Issue           Needs Review        Complex Issue
          ↓                       ↓                  ↓
┌─────────────────┐   ┌─────────────────────┐   ┌──────────────┐
│   Workflow 2:   │   │   Workflow 4:       │   │   Escalate   │
│   Self-Service  │   │   Collaborative     │   │   to Human   │
│   Resolution    │   │   Support Hub       │   │   Support    │
│                 │   │                     │   │              │
│ • Confluence KB │   │ • AI Draft Review   │   │ • Slack      │
│ • Vector Search │   │ • Expert Approval   │   │ • Email      │
│ • AI Solution   │   │ • Send to Customer  │   │ • Dashboard  │
│ • Auto-Send     │   │                     │   │              │
└─────────────────┘   └─────────────────────┘   └──────────────┘
          ↓                       ↓                      ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Customer Receives Solution                    │
│                 (Auto or Human-Approved Response)                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│       Workflow 3: Proactive Issue Detection (Every 15min)        │
│  • Monitor error logs, health metrics, system status             │
│  • Alert teams before customers report issues                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│       Workflow 5: Continuous Learning (Daily at 3 AM)            │
│  • Analyze trends and patterns                                   │
│  • Generate insights reports                                     │
│  • Create bug tickets for recurring issues                       │
│  • Update Confluence knowledge base with new solutions           │
└─────────────────────────────────────────────────────────────────┘
```

## Workflows

This system consists of 5 interconnected n8n workflows:

| # | Workflow | Purpose | Trigger Type |
|---|----------|---------|--------------|
| 1 | Smart Support Intake & Triage | Receive and classify support requests | Webhook |
| 2 | Self-Service Resolution Engine | Auto-resolve simple issues | Sub-workflow |
| 3 | Proactive Issue Detection | Monitor and prevent issues | Schedule (15 min) |
| 4 | Collaborative Support Hub | Human-reviewed resolutions | Sub-workflow |
| 5 | Continuous Learning | Daily insights and improvements | Schedule (daily) |

See the [Workflows README](n8n-workflows/README.md) for detailed workflow documentation.

## Project Structure

```
.
├── README.md                          # This file
├── docs/                              # Documentation
│   ├── QUICK-START.md                # 30-minute setup guide
│   ├── USER-GUIDE.md                 # Support team user guide
│   ├── ADMIN-GUIDE.md                # System administration guide
│   ├── API-REFERENCE.md              # API & webhook documentation
│   ├── BEST-PRACTICES.md            # KB, workflow, and security optimization
│   ├── ERROR-REFERENCE.md           # Error codes and troubleshooting
│   ├── RELEASE-NOTES.md             # Version history and changelog
│   ├── CONFLUENCE-INTEGRATION.md    # Confluence KB setup and maintenance
│   ├── CONFLUENCE-WORKFLOW-DIAGRAM.md # Visual workflow reference
│   ├── JIRA-INTEGRATION.md          # Jira project and escalation setup
│   ├── EMAIL-INTEGRATION.md         # Gmail/email channel setup
│   ├── SLACK-CONFIGURATION.md       # Slack bot setup guide
│   ├── SUPABASE-CLOUD-SETUP.md      # Cloud database configuration
│   ├── AI-PROMPTS-REFERENCE.md      # AI prompt configurations
│   ├── WORKFLOW-TESTING-NOTES.md    # Testing procedures
│   └── WORKFLOW-5-ENHANCEMENTS.md   # WF5 enhancement notes
├── n8n-workflows/                     # n8n workflow files
│   ├── README.md                     # Workflow documentation
│   ├── workflow-1-smart-intake-triage.json
│   ├── workflow-2-self-service-resolution.json
│   ├── workflow-3-proactive-detection.json
│   ├── workflow-4-collaborative-support.json
│   └── workflow-5-continuous-learning.json
└── dashboard/                         # Monitoring and analytics
    ├── README.md                     # Dashboard setup guide
    ├── grafana-dashboard.json        # Grafana dashboard config
    ├── token-tracking-workflow.json  # Token usage monitoring
    └── log-token-usage-workflow.json # Token logging workflow
```

## Prerequisites

Before deploying this system, ensure you have:

- **n8n** - Cloud or self-hosted (v1.0+)
- **PostgreSQL** - Database for case management (Supabase recommended)
- **Anthropic API** - Claude AI for classification and resolution
- **OpenAI API** - Embeddings for knowledge base search
- **Confluence** - Knowledge base, wiki, and project documentation
- **Slack** - Team notifications and alerts
- **Gmail** - Email support channel (optional)
- **Jira** - Bug tracking integration (optional)
- **Grafana** - Monitoring dashboard (optional)

## Technology Stack

- **Orchestration**: n8n (workflow automation)
- **AI**: Claude 3.5 Sonnet (Anthropic), GPT-4 (OpenAI embeddings)
- **Database**: PostgreSQL with vector extensions (pgvector)
- **Vector Store**: Supabase (for semantic search)
- **Knowledge Base**: Confluence (wiki, documentation, institutional knowledge)
- **Integrations**: Slack, Gmail, Jira, Confluence
- **Monitoring**: Grafana, Prometheus-compatible metrics

## Key Capabilities

### 1. Intelligent Classification
AI analyzes support requests and automatically determines:
- **Category** - Authentication, billing, configuration, bug, etc.
- **Priority** - Critical, high, medium, low
- **Sentiment** - Frustrated, neutral, satisfied
- **Complexity** - Simple, moderate, complex
- **Confidence** - AI's certainty in its classification (0-1)

### 2. Multi-Path Resolution
Based on classification and confidence:
- **Self-Service (85%+ confidence)** - Instant AI-generated solutions
- **Collaborative (60-85% confidence)** - AI draft + human approval
- **Escalation (<60% confidence)** - Route to human expert

### 3. Proactive Monitoring
System continuously monitors for:
- Error spikes and anomalies
- Service health degradation
- Recurring customer issues
- Creates alerts before customers report problems

### 4. Confluence Knowledge Base Integration
The system leverages Confluence as the central knowledge repository:
- **Semantic Search** - AI searches Confluence pages using vector embeddings
- **Context-Aware Retrieval** - Finds relevant documentation based on issue context
- **Automatic Updates** - Workflow 5 creates new Confluence pages for novel solutions
- **Wiki Integration** - Accesses product docs, runbooks, troubleshooting guides
- **Institutional Knowledge** - Taps into team expertise stored in Confluence spaces

### 5. Continuous Improvement
Daily analysis provides:
- Top recurring issues and trends
- Knowledge base gap identification
- Automatic bug ticket creation
- Performance metrics and insights
- New Confluence pages for frequently asked questions

## Knowledge Base Architecture

The system uses a hybrid approach combining Confluence and vector search for intelligent knowledge retrieval:

### How It Works

```
Customer Issue Description
         ↓
    [Generate Embedding]
    (OpenAI text-embedding)
         ↓
    [Vector Search]
    (Supabase pgvector)
         ↓
    [Retrieve Top Matches]
    (Confluence page IDs)
         ↓
    [Fetch Full Content]
    (Confluence API)
         ↓
    [AI Synthesis]
    (Claude analyzes & adapts)
         ↓
    Custom Solution
```

### Confluence Structure

Recommended Confluence space organization:

```
Support Knowledge Base (Space)
├── Authentication & Login
│   ├── Password Reset Procedures
│   ├── SSO Configuration
│   └── MFA Troubleshooting
├── Billing & Subscriptions
│   ├── Payment Method Updates
│   ├── Invoice Access
│   └── Refund Policies
├── Product Configuration
│   ├── API Key Management
│   ├── Webhook Setup
│   └── Integration Guides
├── Known Issues & Bugs
│   ├── Current Incident Log
│   └── Resolved Issues Archive
└── Runbooks
    ├── Emergency Procedures
    └── Escalation Workflows
```

### Vector Search Process

1. **Initial Indexing** - All Confluence pages are converted to embeddings on first run
2. **Issue Analysis** - Customer description is converted to a query vector
3. **Similarity Search** - Top 5 most relevant Confluence pages are retrieved
4. **Content Ranking** - Results are scored by relevance and recency
5. **AI Synthesis** - Claude reads the pages and generates a custom solution

### Knowledge Base Updates

Workflow 5 automatically maintains Confluence:
- **Creates new pages** when novel solutions are discovered
- **Links related issues** to create a knowledge graph
- **Archives outdated content** based on resolution success rates
- **Suggests improvements** for low-performing articles

## Documentation

### Getting Started
- **[Quick Start Guide](docs/QUICK-START.md)** - Get running in 30 minutes
- **[User Guide](docs/USER-GUIDE.md)** - For support staff, team leads, and customers
- **[Admin Guide](docs/ADMIN-GUIDE.md)** - System configuration, installation, and maintenance

### API & Webhooks
- **[API Reference](docs/API-REFERENCE.md)** - Webhook endpoints and outgoing webhooks
- **[Error Reference](docs/ERROR-REFERENCE.md)** - Error codes, diagnostics, and troubleshooting

### Integration Guides
- **[Confluence Integration](docs/CONFLUENCE-INTEGRATION.md)** - KB setup, indexing, and maintenance
- **[Slack Configuration](docs/SLACK-CONFIGURATION.md)** - Slack bot and channel setup
- **[Jira Integration](docs/JIRA-INTEGRATION.md)** - Bug tracking and escalation setup
- **[Email Integration](docs/EMAIL-INTEGRATION.md)** - Gmail/email channel configuration
- **[Supabase Cloud Setup](docs/SUPABASE-CLOUD-SETUP.md)** - Database and vector store configuration

### Best Practices & Reference
- **[Best Practices](docs/BEST-PRACTICES.md)** - KB optimization, workflow tuning, security hardening
- **[AI Prompts Reference](docs/AI-PROMPTS-REFERENCE.md)** - AI agent prompt configurations
- **[Confluence Workflow Diagrams](docs/CONFLUENCE-WORKFLOW-DIAGRAM.md)** - Visual reference for KB integration
- **[Release Notes](docs/RELEASE-NOTES.md)** - Version history and changelog

## Dashboard & Monitoring

A Grafana dashboard is included for real-time monitoring:

- **Case Metrics** - Volume, resolution times, status distribution
- **AI Performance** - Accuracy, confidence scores, self-service rate
- **Token Usage** - API costs by workflow and model
- **System Health** - Workflow execution success rates

See the [Dashboard README](dashboard/README.md) for setup instructions.

## Configuration

### Environment Variables

Set these in n8n Settings > Environment Variables:

```bash
# n8n Configuration
N8N_WEBHOOK_BASE_URL=https://your-n8n-instance.com

# Integration IDs
JIRA_CLOUD_ID=your-jira-cloud-id
GITHUB_TOKEN=your-github-token
GITHUB_REPO=your-org/your-repo

# Monitoring
LOG_AGGREGATOR_URL=http://your-log-service:9200

# Email Notifications
LEADERSHIP_EMAIL=support-leadership@company.com
SUPPORT_TEAM_EMAIL=support-team@company.com
```

### API Credentials

Configure in n8n Settings > Credentials:
- PostgreSQL (database connection)
- Anthropic API (Claude AI)
- OpenAI API (embeddings)
- Supabase (vector store)
- Confluence (knowledge base access)
- Slack (notifications)
- Gmail (email support)
- Jira (ticket creation)

## Testing

Test the intake webhook:

```bash
curl -X POST https://your-n8n.com/webhook/support/intake \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "test-customer-123",
    "customer_email": "test@example.com",
    "customer_name": "Test User",
    "description": "I cannot login. Getting error ERR_AUTH_001.",
    "severity": "high",
    "product": "enterprise-gateway",
    "environment": "production"
  }'
```

Expected response:
```json
{
  "success": true,
  "case_id": "uuid-here",
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

## Customization

### Adjusting AI Confidence Thresholds

In Workflow 1 (Smart Intake), modify routing logic:
- **Self-service**: confidence >= 0.85 AND simple issue
- **Collaborative**: confidence >= 0.60
- **Escalate**: confidence < 0.60 OR complex issue

### Modifying Agent Prompts

Customize AI behavior by editing agent prompts in each workflow to match:
- Your product terminology
- Company tone and voice
- Specific classification categories
- Custom resolution templates

### Integration Selection

Enable only the integrations you need:
- **Confluence** - Highly recommended for knowledge base (wiki, docs, runbooks)
- **Slack** - Required for team notifications
- **Gmail** - Optional for email support
- **Jira** - Optional for bug tracking and escalations

### Setting Up Confluence Knowledge Base

1. **Create a Support Space** in Confluence for support articles
2. **Organize Content** with clear categories (Authentication, Billing, etc.)
3. **Index Existing Pages** - The system will automatically generate embeddings
4. **Create Templates** - Standardize solution documentation format
5. **Grant Access** - Ensure n8n has read/write permissions to the space

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Webhook not responding | Ensure workflow is **Active** (toggle in n8n) |
| Database connection errors | Verify PostgreSQL credentials and network access |
| AI classification errors | Check Anthropic API key, quota, and rate limits |
| Empty or incorrect responses | Ensure customer exists in database |
| Token usage spikes | Review prompt sizes and model selection |
| KB search returns no results | Verify Confluence credentials and page indexing |
| Outdated solutions provided | Check Confluence page last-modified dates |

### Debug Mode

1. Open workflow in n8n UI
2. Click "Execute Workflow" with test data
3. Review each node's output
4. Check execution logs for errors

### Check Logs

- **n8n executions**: Workflows > [workflow name] > Executions tab
- **Database logs**: PostgreSQL query logs
- **API logs**: Anthropic/OpenAI API dashboards

## Performance & Costs

### Expected Performance
- **Average resolution time**: 2-5 minutes (vs. 24-48 hours manual)
- **Self-service success rate**: 85%+ for simple issues
- **Human review time saved**: 70%+ reduction
- **Customer satisfaction**: Improved due to faster responses

### Token Usage Estimates
Based on typical support volumes:
- **Workflow 1 (Intake)**: ~1,000 tokens per request
- **Workflow 2 (Self-Service)**: ~3,000 tokens per resolution
- **Workflow 4 (Collaborative)**: ~4,000 tokens per case
- **Workflow 5 (Learning)**: ~10,000 tokens per daily run

Monitor actual usage via the Grafana dashboard.

## Best Practices

### Knowledge Base Management

To maximize AI resolution accuracy:

1. **Write Clear Titles** - Use descriptive, searchable page titles
   - Good: "How to Reset Password for SSO Users"
   - Bad: "Password Issue Fix"

2. **Use Consistent Structure** - Standardize page format
   ```
   ## Problem
   [Clear description of the issue]

   ## Solution
   [Step-by-step resolution]

   ## Prerequisites
   [Required access, tools, or conditions]

   ## Related Articles
   [Links to related Confluence pages]
   ```

3. **Tag Appropriately** - Use Confluence labels for categorization
   - Product names (web-portal, mobile-app, api)
   - Issue types (authentication, billing, performance)
   - Severity (critical, high, medium, low)

4. **Keep Content Fresh** - Review and update pages quarterly
   - Archive outdated solutions
   - Update screenshots and examples
   - Add new edge cases as they're discovered

5. **Link Related Content** - Create a knowledge graph
   - Cross-reference related issues
   - Link to product documentation
   - Reference relevant runbooks

6. **Use Rich Media** - Enhance understanding
   - Screenshots of error messages
   - Diagrams of system architecture
   - Code snippets with syntax highlighting
   - Video walkthroughs for complex procedures

### AI Solution Quality

To improve AI-generated solutions:

- **Review AI Responses** - Use Workflow 4 for quality control
- **Provide Feedback** - Mark solutions as helpful/unhelpful
- **Update Prompts** - Refine agent instructions based on outcomes
- **Monitor Confidence** - Lower thresholds if too many escalations

## Security & Privacy

- All customer data stored in your PostgreSQL database
- API keys stored securely in n8n credentials
- No data sent to third parties except AI providers (Anthropic, OpenAI)
- Review AI responses before sending to customers (collaborative mode)
- Audit logs maintained for all case interactions

## Roadmap

Future enhancements under consideration:
- [ ] Multi-language support for Confluence KB and responses
- [ ] Voice/phone channel integration
- [ ] Advanced sentiment analysis
- [ ] Customer satisfaction predictions
- [ ] Auto-escalation based on customer value
- [ ] Integration with additional ticketing systems
- [ ] Confluence page analytics and usage tracking
- [ ] Automatic knowledge graph visualization
- [ ] AI-powered Confluence page recommendations

## Contributing

This is an internal project. For changes or improvements:
1. Test thoroughly in a development n8n instance
2. Document changes in relevant workflow README
3. Update this README if architecture changes
4. Notify the team before deploying to production

## License

Internal use only. All rights reserved.

## Support

For issues with this system:
1. Check the [troubleshooting section](#troubleshooting)
2. Review workflow execution logs in n8n
3. Consult the [documentation](docs/)
4. Contact the platform team

---

**Version**: 2.0
**Last Updated**: January 2026
**Maintained By**: Operations Team
