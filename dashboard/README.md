# CX-Catalyst - KPI Dashboard

Grafana-based dashboard for monitoring system effectiveness, savings, and AI token usage.

---

## Table of Contents

1. [Dashboard Overview](#dashboard-overview)
2. [Installation Options](#installation-options)
   - [Grafana Cloud](#option-1-grafana-cloud-recommended)
   - [Self-Hosted (Docker)](#option-2-self-hosted-docker)
   - [Self-Hosted (Binary)](#option-3-self-hosted-binary)
3. [Quick Setup](#quick-setup)
4. [KPI Categories](#kpi-categories)
5. [Files Reference](#files-reference)
6. [Configuration](#configuration)
7. [Token Tracking Setup](#token-tracking-setup)
8. [Customization](#customization)

---

## Dashboard Overview

### Panel Layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         EXECUTIVE SUMMARY ROW                            │
├──────────┬──────────┬──────────┬──────────┬──────────┬─────────────────┤
│  Cases   │Resolution│  CSAT    │   Cost   │  Token   │   Time Saved    │
│  Today   │   Rate   │  Score   │ Savings  │  Budget  │    (Hours)      │
│   127    │   94%    │   4.7    │  $4,250  │   72%    │      48.5       │
└──────────┴──────────┴──────────┴──────────┴──────────┴─────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         CASE VOLUME & RESOLUTION                         │
├─────────────────────────────────┬───────────────────────────────────────┤
│   Cases Over Time (Line)        │   Resolution by Path (Pie)            │
│   - Total cases                 │   - Self-service: 65%                 │
│   - Resolved                    │   - Collaborative: 25%                │
│   - Escalated                   │   - Escalated: 10%                    │
└─────────────────────────────────┴───────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         AI PERFORMANCE                                   │
├─────────────────────────────────┬───────────────────────────────────────┤
│   Confidence Distribution       │   AI Accuracy Over Time               │
│   (Histogram)                   │   - Approval rate                     │
│                                 │   - Edit rate                         │
│                                 │   - Rejection rate                    │
└─────────────────────────────────┴───────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         TOKEN USAGE & COSTS                              │
├─────────────────────────────────┬───────────────────────────────────────┤
│   Daily Token Consumption       │   Budget Exhaustion Gauge             │
│   - Input tokens                │   ┌─────────────────┐                 │
│   - Output tokens               │   │     72%         │ ← Monthly       │
│   - By workflow                 │   │   ████████░░    │                 │
│                                 │   └─────────────────┘                 │
└─────────────────────────────────┴───────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         EFFICIENCY & SAVINGS                             │
├─────────────────────────────────┬───────────────────────────────────────┤
│   Time Saved (Stacked Bar)      │   Cost Comparison                     │
│   - Per category                │   - Manual cost baseline              │
│   - Cumulative savings          │   - AI-assisted cost                  │
│                                 │   - Net savings                       │
└─────────────────────────────────┴───────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         IMPROVEMENT OPPORTUNITIES                        │
├─────────────────────────────────┬───────────────────────────────────────┤
│   Top Escalation Reasons        │   KB Coverage Gaps                    │
│   (Table)                       │   (Table with suggested articles)     │
│                                 │                                       │
└─────────────────────────────────┴───────────────────────────────────────┘
```

---

## Installation Options

Choose your preferred Grafana deployment method. All options work with this dashboard.

### Option 1: Grafana Cloud (Recommended)

Grafana Cloud is the easiest way to get started - no infrastructure to manage.

#### Step 1: Create Grafana Cloud Account

1. Go to [grafana.com/cloud](https://grafana.com/cloud)
2. Click **Create free account** (free tier includes 10k metrics, 50GB logs)
3. Choose your cloud region
4. Complete signup

#### Step 2: Access Your Grafana Instance

1. After signup, you'll receive a URL like: `https://your-org.grafana.net`
2. Log in with your credentials
3. You'll land on the Grafana home page

#### Step 3: Add PostgreSQL Data Source

1. Click the **gear icon** (⚙️) → **Data sources**
2. Click **Add data source**
3. Search for and select **PostgreSQL**
4. Configure the connection:

```
Name: Support Database
Host: your-db-host.com:5432
Database: support_system
User: your_db_user
Password: your_db_password
TLS/SSL Mode: require (recommended for cloud databases)
```

**Important for Cloud:** Your PostgreSQL database must be accessible from the internet. Options:
- Use a cloud database (Supabase, AWS RDS, Google Cloud SQL, etc.)
- Configure firewall rules to allow Grafana Cloud IPs
- Use Grafana Cloud's Private Data Source Connect for private networks

#### Step 4: Allow Grafana Cloud IPs (if using firewall)

Grafana Cloud connects from these IP ranges. Add to your database firewall:

```
# US Region
35.226.75.195/32
35.202.127.210/32
34.134.66.194/32

# EU Region
34.90.196.48/32
34.91.96.108/32
35.204.174.85/32

# Check current IPs at:
# https://grafana.com/docs/grafana-cloud/reference/allow-list/
```

#### Step 5: Import Dashboard

1. Click **Dashboards** → **Import**
2. Click **Upload JSON file**
3. Select `grafana-dashboard.json`
4. Select your PostgreSQL data source
5. Click **Import**

#### Grafana Cloud Pricing

| Tier | Metrics | Logs | Cost |
|------|---------|------|------|
| Free | 10,000 series | 50 GB | $0/mo |
| Pro | 25,000 series | 100 GB | $29/mo |
| Advanced | Custom | Custom | Custom |

The free tier is sufficient for most small-medium deployments.

#### Connecting to Private Databases (PDC)

If your PostgreSQL database is in a private network (not internet-accessible), use **Private Data Source Connect (PDC)**.

1. **Install PDC Agent** on a server in your private network:

```bash
# Download PDC agent
curl -O https://grafana.com/api/pdc/download/latest/linux/amd64/pdc

# Make executable
chmod +x pdc

# Run with your token (get from Grafana Cloud → Connections → PDC)
./pdc -token YOUR_PDC_TOKEN -cluster your-org
```

2. **Configure as systemd service** (recommended):

```bash
sudo cat > /etc/systemd/system/grafana-pdc.service << 'EOF'
[Unit]
Description=Grafana Private Data Source Connect
After=network.target

[Service]
Type=simple
User=grafana-pdc
ExecStart=/usr/local/bin/pdc -token YOUR_PDC_TOKEN -cluster your-org
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable grafana-pdc
sudo systemctl start grafana-pdc
```

3. **Add data source using PDC**:
   - In Grafana Cloud, go to **Connections** → **Data Sources**
   - Add PostgreSQL
   - Enable **Private data source connect**
   - Enter your private database host (e.g., `10.0.1.50:5432`)

---

### Option 2: Self-Hosted (Docker)

Best for teams who want full control and have Docker infrastructure.

#### Step 1: Create Docker Compose File

```bash
mkdir grafana-kpi && cd grafana-kpi

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana-kpi
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=your-secure-password
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_ROOT_URL=https://grafana.yourdomain.com
      # Database connection (optional - for HA setups)
      # - GF_DATABASE_TYPE=postgres
      # - GF_DATABASE_HOST=your-db:5432
      # - GF_DATABASE_NAME=grafana
      # - GF_DATABASE_USER=grafana
      # - GF_DATABASE_PASSWORD=grafana-password
    volumes:
      - grafana_data:/var/lib/grafana
      - ./provisioning:/etc/grafana/provisioning
    networks:
      - monitoring

volumes:
  grafana_data:

networks:
  monitoring:
    driver: bridge
EOF
```

#### Step 2: Create Provisioning Directory

```bash
mkdir -p provisioning/datasources
mkdir -p provisioning/dashboards
```

#### Step 3: Add Data Source Provisioning

```bash
cat > provisioning/datasources/postgres.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Support Database
    type: postgres
    uid: support-postgres
    url: your-db-host:5432
    database: support_system
    user: your_db_user
    secureJsonData:
      password: your_db_password
    jsonData:
      sslmode: require
      maxOpenConns: 10
      maxIdleConns: 2
      connMaxLifetime: 14400
      postgresVersion: 1500
      timescaledb: false
    editable: true
    isDefault: true
EOF
```

#### Step 4: Add Dashboard Provisioning

```bash
cat > provisioning/dashboards/dashboards.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'Support KPI Dashboards'
    orgId: 1
    folder: 'Support'
    folderUid: 'support-dashboards'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards/json
EOF

mkdir -p provisioning/dashboards/json
cp /path/to/grafana-dashboard.json provisioning/dashboards/json/
```

#### Step 5: Start Grafana

```bash
docker-compose up -d
```

#### Step 6: Access Grafana

1. Open `http://localhost:3000` (or your configured domain)
2. Log in with admin / your-secure-password
3. Dashboard will be automatically loaded

#### Docker with SSL (Production)

For production, add a reverse proxy:

```yaml
# Add to docker-compose.yml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - grafana
```

---

### Option 3: Self-Hosted (Binary)

For bare-metal or VM installations without Docker.

#### Ubuntu/Debian

```bash
# Add Grafana APT repository
sudo apt-get install -y apt-transport-https software-properties-common wget
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Install Grafana
sudo apt-get update
sudo apt-get install grafana

# Start service
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

#### RHEL/CentOS/Fedora

```bash
# Add Grafana YUM repository
cat > /etc/yum.repos.d/grafana.repo << 'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# Install Grafana
sudo yum install grafana

# Start service
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

#### macOS (Homebrew)

```bash
brew install grafana
brew services start grafana
```

#### Windows

1. Download installer from [grafana.com/grafana/download](https://grafana.com/grafana/download?platform=windows)
2. Run the MSI installer
3. Grafana starts automatically as a Windows service
4. Access at `http://localhost:3000`

#### Configuration File Location

| OS | Config File | Data Directory |
|----|-------------|----------------|
| Linux | `/etc/grafana/grafana.ini` | `/var/lib/grafana` |
| macOS | `/usr/local/etc/grafana/grafana.ini` | `/usr/local/var/lib/grafana` |
| Windows | `C:\Program Files\GrafanaLabs\grafana\conf\defaults.ini` | `C:\Program Files\GrafanaLabs\grafana\data` |

#### Add Provisioning (Binary Install)

```bash
# Linux example
sudo mkdir -p /etc/grafana/provisioning/datasources
sudo mkdir -p /etc/grafana/provisioning/dashboards/json

# Copy provisioning files
sudo cp datasources.yaml /etc/grafana/provisioning/datasources/
sudo cp grafana-dashboard.json /etc/grafana/provisioning/dashboards/json/

# Create dashboard provider config
sudo cat > /etc/grafana/provisioning/dashboards/dashboards.yml << 'EOF'
apiVersion: 1
providers:
  - name: 'Support KPI'
    folder: 'Support'
    type: file
    options:
      path: /etc/grafana/provisioning/dashboards/json
EOF

# Restart Grafana
sudo systemctl restart grafana-server
```

---

### Comparison: Cloud vs Self-Hosted

| Feature | Grafana Cloud | Self-Hosted |
|---------|--------------|-------------|
| **Setup Time** | 5 minutes | 30-60 minutes |
| **Maintenance** | None | You manage updates |
| **Cost** | Free tier available, then paid | Infrastructure costs only |
| **Scaling** | Automatic | Manual |
| **Data Location** | Cloud provider | Your infrastructure |
| **Private Network** | Requires tunnel | Direct access |
| **Alerting** | Included | Included |
| **SSO/Auth** | Easy setup | Configure yourself |

**Recommendation:**
- **Grafana Cloud** - Best for most teams, especially if your database is cloud-hosted
- **Self-Hosted Docker** - Best for teams with existing container infrastructure
- **Self-Hosted Binary** - Best for traditional VM/bare-metal environments

---

## Quick Setup

After installing Grafana (any method above), complete these steps.

### Prerequisites

- Grafana 9.0+ installed (via any method above)
- PostgreSQL database with support system schema
- n8n with workflows deployed

### Step 1: Database Setup

Run the schema additions for dashboard metrics:

```bash
psql -h your-db-host -U postgres -d support_system -f schema-additions.sql
```

Then create the views:

```bash
psql -h your-db-host -U postgres -d support_system -f views.sql
```

### Step 2: Configure Grafana Datasource

**Option A: Provisioning (Recommended)**

Copy `datasources.yaml` to Grafana's provisioning directory:

```bash
cp datasources.yaml /etc/grafana/provisioning/datasources/
```

Update the environment variables or replace placeholders:
- `${DB_HOST}` - PostgreSQL host
- `${DB_USER}` - Database user
- `${DB_PASSWORD}` - Database password

**Option B: Manual Configuration**

1. Open Grafana UI
2. Go to **Configuration** > **Data Sources**
3. Click **Add data source**
4. Select **PostgreSQL**
5. Configure:
   - **Name:** Support Database
   - **Host:** your-db-host:5432
   - **Database:** support_system
   - **User/Password:** your credentials
   - **SSL Mode:** require

### Step 3: Import Dashboard

1. Open Grafana UI
2. Go to **Dashboards** > **Import**
3. Upload `grafana-dashboard.json`
4. Select your PostgreSQL datasource
5. Click **Import**

### Step 4: Import Token Tracking Workflows

In n8n:

1. Import `token-tracking-workflow.json` (background tracker)
2. Import `log-token-usage-workflow.json` (sub-workflow for logging)
3. Configure credentials
4. Activate the token tracking workflow

---

## KPI Categories

### Effectiveness Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| Case Resolution Rate | % cases resolved | >90% |
| First Contact Resolution | % resolved on first interaction | >70% |
| AI Confidence Accuracy | How well confidence predicts success | ±5% |
| Customer Satisfaction | CSAT score (1-5) | >4.5 |

### Efficiency Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| Average Resolution Time | Minutes to resolve | <15 min |
| Self-Service Rate | % handled without human | >85% |
| Human Intervention Rate | % requiring human review | <15% |
| Time Saved | Hours saved vs manual | Track |

### Cost Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| Cost per Case | Total cost / cases | <$5 |
| Total Savings | Baseline - Actual cost | Track |
| Token Costs | AI API spend | Within budget |
| ROI | Savings / Investment | >500% |

### Token Usage Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| Daily Consumption | Tokens used per day | Track |
| Budget Utilization | % of monthly budget | <95% |
| Cost per Case | AI cost / case | <$2 |
| Projected Exhaustion | Date budget runs out | After month end |

### Improvement Indicators

| Metric | Description | Action |
|--------|-------------|--------|
| Top Escalation Reasons | Why cases escalate | Create KB articles |
| KB Coverage Gaps | Low self-service categories | Add documentation |
| Low Confidence Categories | AI struggles | Improve training |
| Recurring Issues | Frequent same problems | Fix root cause |

---

## Files Reference

| File | Purpose |
|------|---------|
| `schema-additions.sql` | Database tables for token tracking, budgets, metrics |
| `views.sql` | Pre-computed views for efficient Grafana queries |
| `token-tracking-workflow.json` | n8n workflow for periodic token usage polling |
| `log-token-usage-workflow.json` | Sub-workflow called after AI operations |
| `grafana-dashboard.json` | Complete Grafana dashboard definition |
| `datasources.yaml` | Grafana datasource provisioning config |

---

## Configuration

### Token Budgets

Configure monthly and daily token budgets in the database:

```sql
-- Update monthly Anthropic budget
UPDATE token_budgets
SET token_limit = 15000000,
    cost_limit_usd = 4500.00
WHERE budget_name = 'Anthropic Monthly';

-- Add new budget
INSERT INTO token_budgets (
    budget_name, provider, budget_type,
    token_limit, cost_limit_usd,
    period_start, period_end
)
VALUES (
    'Claude Opus Monthly', 'anthropic', 'monthly',
    5000000, 2000.00,
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'
);
```

### Baseline Configuration

Adjust savings calculations by updating baselines:

```sql
-- Update manual cost baseline
UPDATE baseline_config
SET config_value = 25.00
WHERE config_key = 'manual_cost_per_case';

-- Update hourly support cost
UPDATE baseline_config
SET config_value = 40.00
WHERE config_key = 'hourly_support_cost';
```

### API Pricing

Update when pricing changes:

```sql
-- Mark old pricing as not current
UPDATE api_pricing
SET is_current = FALSE
WHERE provider = 'anthropic' AND model = 'claude-sonnet-4';

-- Insert new pricing
INSERT INTO api_pricing (
    provider, model,
    input_price_per_million, output_price_per_million,
    effective_from
)
VALUES (
    'anthropic', 'claude-sonnet-4',
    2.50, 12.50,  -- New prices
    '2026-02-01'
);
```

---

## Token Tracking Setup

### Method 1: Background Polling (token-tracking-workflow.json)

This workflow runs every 5 minutes and:
1. Queries Anthropic/OpenAI usage APIs (if available)
2. Records aggregate token usage
3. Checks budget thresholds
4. Sends Slack alerts when thresholds exceeded

**Setup:**
1. Import the workflow
2. Configure API credentials for usage endpoints
3. Activate the workflow

### Method 2: Per-Request Logging (log-token-usage-workflow.json)

Call this sub-workflow after each AI operation to log token usage.

**Integration in Main Workflows:**

Add an "Execute Workflow" node after AI agent nodes:

```javascript
// In a Code node, prepare the data
return {
  json: {
    workflow_name: 'workflow-1-intake',
    case_id: $json.case_id,
    provider: 'anthropic',
    model: 'claude-sonnet-4',
    operation_type: 'triage',
    // Token counts from AI response
    input_tokens: $json.response?.usage?.input_tokens || 0,
    output_tokens: $json.response?.usage?.output_tokens || 0,
    latency_ms: $json.response_time_ms,
    success: true
  }
};
```

Then connect to Execute Workflow node calling "Log Token Usage".

### Viewing Token Data

The dashboard shows:
- **Daily Token Consumption**: Stacked bar chart by provider
- **Budget Utilization**: Gauge showing % of monthly budget
- **Daily AI Costs**: Line chart of actual spending
- **Projected Exhaustion**: Calculated date when budget runs out

---

## Customization

### Adding New Panels

1. Edit dashboard in Grafana
2. Click **Add panel**
3. Write PostgreSQL query against the views
4. Configure visualization
5. Save dashboard
6. Export and update `grafana-dashboard.json`

### Example Queries

**Cases by Hour (Today):**
```sql
SELECT
    DATE_TRUNC('hour', created_at) as time,
    COUNT(*) as cases
FROM cases
WHERE created_at >= CURRENT_DATE
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY time
```

**Token Usage by Workflow:**
```sql
SELECT
    workflow_name,
    SUM(total_tokens) as tokens,
    SUM(cost_usd) as cost
FROM token_usage
WHERE recorded_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY workflow_name
ORDER BY tokens DESC
```

**Self-Service Rate Trend:**
```sql
SELECT
    metric_date as time,
    self_service_rate
FROM v_daily_kpi
WHERE metric_date >= $__timeFrom()::date
ORDER BY metric_date
```

### Alert Rules

Create Grafana alerts for:

1. **Budget Warning**
   - Condition: `v_budget_utilization.token_utilization_pct > 80`
   - Channel: Slack #support-alerts

2. **Low Resolution Rate**
   - Condition: `v_daily_kpi.resolution_rate < 70` for 2 days
   - Channel: Email team lead

3. **High Escalation Rate**
   - Condition: Daily escalations > 20% of cases
   - Channel: Slack #support-alerts

### Scheduled Reports

Use Grafana's reporting feature to:
- Send daily KPI snapshot at 8 AM
- Send weekly summary on Mondays
- Send monthly executive report

---

## Troubleshooting

### Dashboard Shows No Data

1. Check PostgreSQL connection in datasource settings
2. Verify views exist: `SELECT * FROM v_executive_summary`
3. Ensure cases exist in the database
4. Check time range in dashboard (top right)

### Token Tracking Not Working

1. Verify token tracking workflow is active
2. Check workflow execution logs in n8n
3. Test database insert manually
4. Verify API credentials for usage endpoints

### Calculations Seem Wrong

1. Check baseline_config values
2. Verify api_pricing is current
3. Review formula in views.sql
4. Test view queries directly in PostgreSQL

---

## Maintenance

### Daily

- Dashboard auto-refreshes every 5 minutes
- Token tracking runs automatically

### Weekly

- Review improvement opportunities table
- Check for pricing updates

### Monthly

- Update token budgets for new period:
  ```sql
  UPDATE token_budgets
  SET period_start = DATE_TRUNC('month', CURRENT_DATE),
      period_end = DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'
  WHERE budget_type = 'monthly';
  ```

- Archive old daily metrics if needed
- Review and update baseline costs

---

*Dashboard Documentation v1.0 - January 2026*
