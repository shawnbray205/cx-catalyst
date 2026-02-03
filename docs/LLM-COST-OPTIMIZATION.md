# CX-Catalyst — LLM Cost Optimization Report

Vendor-agnostic analysis of LLM usage, model selection, and cost reduction strategies.

**Date:** January 2026
**Scope:** All 5 support workflows, 2 embedding workflows, token tracking infrastructure

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Assessment](#current-state-assessment)
3. [Model Pricing Landscape](#model-pricing-landscape)
4. [Optimization Recommendations](#optimization-recommendations)
5. [Batch Processing Strategy](#batch-processing-strategy)
6. [Prompt Caching Strategy](#prompt-caching-strategy)
7. [Max Tokens Right-Sizing](#max-tokens-right-sizing)
8. [Projected Cost Savings](#projected-cost-savings)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Risk Assessment](#risk-assessment)

---

## Executive Summary

The CX-Catalyst system currently runs **7 Claude Sonnet agents** across 5 workflows, all using the same premium-tier model regardless of task complexity. This analysis identifies **4 major optimization levers** that can reduce LLM costs by an estimated **55–65%** without sacrificing accuracy:

1. **Model Tiering** — Use lighter models for classification/routing tasks (~70% savings on those calls)
2. **Batch Processing** — Use batch APIs for scheduled workflows (~50% savings on WF3/WF5)
3. **Prompt Caching** — Cache repeated system prompts (~90% savings on cached reads)
4. **Max Tokens Right-Sizing** — Reduce token limits for structured outputs (~15% savings)

---

## Current State Assessment

### LLM Usage Inventory

| Workflow | Agent | Model | Temp | Max Tokens | Execution Frequency |
|----------|-------|-------|------|------------|---------------------|
| WF1: Intake & Triage | Triage Classifier | claude-sonnet-4-5-20250929 | 0.1 | 4,096 | Per incoming ticket (real-time) |
| WF2: Self-Service Resolution | Solution Generator | claude-sonnet-4-5-20250929 | 0.4 | 4,096 | Per triaged ticket (real-time) |
| WF3: Proactive Detection | Anomaly Analyzer | claude-sonnet-4-5-20250929 | 0.3 | 4,096 | Every 15 minutes (scheduled) |
| WF4: Collaborative Hub | Research Drafter | claude-sonnet-4-20250514 | 0.4 | 4,096 | Per medium-confidence ticket |
| WF5: Continuous Learning | Pattern Analyzer | claude-sonnet-4-20250514 | 0.4 | 4,096 | Daily (scheduled) |
| WF5: Continuous Learning | Article Generator | claude-sonnet-4-20250514 | 0.5 | 4,096 | Daily (scheduled) |

### Embedding Usage

| Workflow | Model | Dimensions | Execution |
|----------|-------|------------|-----------|
| KB Embedding Generator v2 | text-embedding-3-small | 1,536 | On-demand (batch 50) |
| Confluence KB Indexer | text-embedding-3-small | 1,536 | Real-time per article update |

### Current Pricing (Per Million Tokens)

| Model | Input | Output | Cache Read |
|-------|-------|--------|------------|
| claude-sonnet-4-5-20250929 | $3.00 | $15.00 | $0.30 |
| claude-sonnet-4-20250514 | $3.00 | $15.00 | $0.30 |
| text-embedding-3-small | $0.02 | N/A | N/A |

### Estimated Current Cost Per 1,000 Tickets

Assumptions: Average input ~1,500 tokens, average output ~800 tokens per agent call. Not all tickets hit every workflow (e.g., WF4 handles ~30% of tickets).

| Workflow | Calls/1K Tickets | Input Tokens | Output Tokens | Cost |
|----------|-----------------|--------------|---------------|------|
| WF1 (Triage) | 1,000 | 1,500,000 | 800,000 | $16.50 |
| WF2 (Solution) | 1,000 | 1,500,000 | 800,000 | $16.50 |
| WF3 (Detection) | ~1,440* | 2,160,000 | 1,152,000 | $23.76 |
| WF4 (Research) | ~300 | 450,000 | 240,000 | $4.95 |
| WF5 (Analysis) | ~30** | 45,000 | 24,000 | $0.50 |
| WF5 (Articles) | ~30** | 45,000 | 24,000 | $0.50 |
| Embeddings | ~1,000 | 750,000 | N/A | $0.02 |
| **Total** | | | | **~$62.73** |

*WF3 runs 96x/day (every 15 min); assumed ~15 days to process 1K tickets
**WF5 runs daily; assumed ~30 days

> **Key finding:** WF3 (Proactive Detection) is the most expensive workflow due to high execution frequency, not ticket volume. WF1 and WF2 are the highest per-ticket costs.

---

## Model Pricing Landscape

### Tier 1: Premium (Complex Reasoning)

Best for: Solution generation, nuanced analysis, complex research drafts.

| Model | Provider | Input | Output | Batch Input | Batch Output |
|-------|----------|-------|--------|-------------|--------------|
| claude-sonnet-4-5-20250929 | Anthropic | $3.00 | $15.00 | $1.50 | $7.50 |
| claude-sonnet-4-20250514 | Anthropic | $3.00 | $15.00 | $1.50 | $7.50 |
| gpt-4o | OpenAI | $2.50 | $10.00 | $1.25 | $5.00 |
| gemini-2.0-pro | Google | $1.25 | $10.00 | $0.63 | $5.00 |

### Tier 2: Mid-Range (Structured Tasks)

Best for: Classification, triage, anomaly detection with structured output.

| Model | Provider | Input | Output | Batch Input | Batch Output |
|-------|----------|-------|--------|-------------|--------------|
| claude-haiku-3-5-20241022 | Anthropic | $0.80 | $4.00 | $0.40 | $2.00 |
| gpt-4o-mini | OpenAI | $0.15 | $0.60 | $0.075 | $0.30 |
| gemini-2.0-flash | Google | $0.10 | $0.40 | $0.05 | $0.20 |
| mistral-small | Mistral | $0.10 | $0.30 | N/A | N/A |

### Tier 3: Budget (Simple Extraction)

Best for: Data extraction, formatting, simple transformations.

| Model | Provider | Input | Output |
|-------|----------|-------|--------|
| gemini-2.0-flash-lite | Google | $0.025 | $0.10 |
| deepseek-chat (V3) | DeepSeek | $0.27 | $1.10 |

### Embedding Models

| Model | Provider | Cost/MTok | Dimensions |
|-------|----------|-----------|------------|
| text-embedding-3-small | OpenAI | $0.02 | 1,536 |
| text-embedding-3-large | OpenAI | $0.13 | 3,072 |
| embed-v4.0 | Cohere | $0.10 | 1,024 |

> **Embedding verdict:** text-embedding-3-small at $0.02/MTok is already the most cost-effective option with strong performance. No change needed.

---

## Optimization Recommendations

### Recommendation 1: Model Tiering by Task Complexity

Replace premium models with appropriately-sized models based on task requirements.

#### WF1: Intake & Triage — Downgrade to Mid-Range

**Current:** claude-sonnet-4-5-20250929 ($3.00/$15.00)
**Recommended:** gemini-2.0-flash ($0.10/$0.40) or gpt-4o-mini ($0.15/$0.60)

**Rationale:** Triage is a structured classification task that outputs a fixed JSON schema (category, priority, severity, complexity, resolution path, confidence score). The temperature is already set to 0.1, indicating deterministic behavior is desired. Mid-range models excel at structured classification tasks and consistently produce valid JSON.

**Why these models:**
- gemini-2.0-flash: 30x cheaper input, 37x cheaper output, excellent at structured output with JSON mode
- gpt-4o-mini: 20x cheaper input, 25x cheaper output, strong JSON mode support
- Both models handle classification tasks with comparable accuracy to Sonnet when the output schema is well-defined

**Risk:** Low. Classification with constrained output format is well within mid-range model capabilities. The low temperature (0.1) further reduces variability. Recommend A/B testing on 100 tickets before full rollover.

**Savings per 1,000 tickets:** $16.50 → ~$0.55 (gemini-2.0-flash) = **$15.95 saved (97%)**

#### WF2: Self-Service Resolution — Keep Premium (with caching)

**Current:** claude-sonnet-4-5-20250929 ($3.00/$15.00)
**Recommended:** Keep claude-sonnet-4-5-20250929, add prompt caching

**Rationale:** Solution generation requires nuanced, empathetic, multi-step reasoning grounded in KB articles. This is the customer-facing output — quality directly impacts CSAT and resolution rates. Premium model justified.

**Optimization:** Apply prompt caching to the system prompt (see Prompt Caching section).

**Savings per 1,000 tickets:** ~$3.50 from caching (see below)

#### WF3: Proactive Detection — Downgrade to Mid-Range + Batch

**Current:** claude-sonnet-4-5-20250929 ($3.00/$15.00)
**Recommended:** gpt-4o-mini ($0.15/$0.60) with batch API

**Rationale:** Anomaly detection runs on a 15-minute schedule analyzing metrics data. The output is a structured assessment (anomaly type, severity, affected systems, recommended action). This is an internal analytical task — no customer-facing output. The analysis window is not time-critical (15-minute cadence already implies tolerance for slight delays).

**Why this model:** gpt-4o-mini handles structured analytical tasks well. Batch API adds 50% savings on top of the model cost reduction. Combined savings are significant given WF3's high execution frequency.

**Savings per 1,000 tickets:** $23.76 → ~$0.49 (gpt-4o-mini batch) = **$23.27 saved (98%)**

#### WF4: Collaborative Hub — Keep Premium (with caching)

**Current:** claude-sonnet-4-20250514 ($3.00/$15.00)
**Recommended:** Keep claude-sonnet-4-20250514, add prompt caching

**Rationale:** Research drafts for human review require high-quality reasoning and comprehensive solutions. These are medium-confidence cases that couldn't be auto-resolved — they need the best model. Since this workflow only handles ~30% of tickets, the absolute cost is already moderate.

**Savings per 1,000 tickets:** ~$1.05 from caching

#### WF5: Continuous Learning — Downgrade Pattern Analysis + Batch Both

**Current:** Two claude-sonnet-4-20250514 agents ($3.00/$15.00 each)
**Recommended:**
- Pattern Analyzer → gpt-4o-mini batch ($0.075/$0.30)
- Article Generator → Keep claude-sonnet-4-20250514 batch ($1.50/$7.50)

**Rationale:**
- Pattern analysis is internal data crunching (trend detection, frequency counts, correlation). Mid-range model is sufficient.
- Article generation creates customer-facing KB content that must be well-written, accurate, and comprehensive. Premium model justified, but batch API is fine since it runs daily (no real-time requirement).

**Savings per 1,000 tickets:** ~$0.65 saved

### Summary of Model Recommendations

| Workflow | Current Model | Recommended Model | Reason |
|----------|--------------|-------------------|--------|
| WF1: Triage | claude-sonnet-4-5 | **gemini-2.0-flash** | Structured classification, 30x cheaper |
| WF2: Solutions | claude-sonnet-4-5 | claude-sonnet-4-5 (keep) | Customer-facing quality critical |
| WF3: Detection | claude-sonnet-4-5 | **gpt-4o-mini** (batch) | Internal analytics, structured output |
| WF4: Research | claude-sonnet-4 | claude-sonnet-4 (keep) | Complex reasoning for human review |
| WF5: Patterns | claude-sonnet-4 | **gpt-4o-mini** (batch) | Data crunching, trend detection |
| WF5: Articles | claude-sonnet-4 | claude-sonnet-4 (**batch**) | Quality content, but not time-sensitive |
| Embeddings | text-embedding-3-small | text-embedding-3-small (keep) | Already most cost-effective |

---

## Batch Processing Strategy

### Eligible Workflows

Batch APIs process requests asynchronously (typically within 24 hours) at 50% reduced cost. Workflows that do NOT require real-time responses are eligible.

| Workflow | Current Frequency | Batch Eligible | Batch Discount |
|----------|-------------------|----------------|----------------|
| WF1: Triage | Real-time | No — customer waiting | N/A |
| WF2: Solution | Real-time | No — customer waiting | N/A |
| WF3: Detection | Every 15 min | **Yes** — schedule allows batching | 50% off |
| WF4: Research | On-demand | No — feeds Slack review queue | N/A |
| WF5: Patterns | Daily | **Yes** — daily schedule | 50% off |
| WF5: Articles | Daily | **Yes** — daily schedule | 50% off |

### Batch API Implementation

#### Anthropic Batch API
- Submit up to 10,000 requests per batch
- Results available within 24 hours
- 50% discount on input and output tokens
- Endpoint: `POST /v1/messages/batches`
- Status polling: `GET /v1/messages/batches/{batch_id}`

#### OpenAI Batch API
- Submit via JSONL file upload
- Results within 24 hours
- 50% discount on all tokens
- Endpoint: `POST /v1/batches`

#### Google Batch API
- Available for Gemini models
- 50% discount
- Suitable for WF3 if gemini-2.0-flash is adopted for triage

### Implementation in n8n

For WF3 (Proactive Detection):
1. Accumulate metrics data in a staging table or queue
2. At the 15-minute interval, submit a batch request instead of synchronous call
3. Use a separate polling workflow to check batch completion and process results
4. Alert on anomalies once batch results are available

For WF5 (Continuous Learning):
1. Collect the day's case data as normal
2. Submit pattern analysis as a batch request
3. Once patterns are returned, submit article generation as a second batch
4. Process results and publish to Confluence

> **Note:** Batch processing adds latency (minutes to hours). For WF3, consider whether 15-minute anomaly detection requires sub-minute LLM response. If the detection cadence can be relaxed to 30–60 minutes, batch becomes more practical.

---

## Prompt Caching Strategy

### How Prompt Caching Works (Anthropic)

Anthropic's prompt caching allows frequently repeated content (system prompts, instruction blocks) to be cached server-side:

- **Cache write:** 25% more than base input price (one-time)
- **Cache read:** 90% less than base input price (subsequent calls)
- **Cache TTL:** 5 minutes (resets on each cache hit)
- **Minimum cacheable:** 1,024 tokens (Sonnet), 2,048 tokens (Haiku)

### Caching Opportunities

| Workflow | System Prompt Size (est.) | Calls/Hour (est.) | Cache Benefit |
|----------|--------------------------|-------------------|---------------|
| WF1: Triage | ~800 tokens | Variable | Moderate — depends on ticket volume |
| WF2: Solution | ~1,200 tokens | Variable | High — large system prompt with KB context template |
| WF3: Detection | ~900 tokens | 4 (every 15 min) | High — consistent 15-min cadence keeps cache warm |
| WF4: Research | ~1,100 tokens | Variable | Moderate — lower volume |
| WF5: Patterns | ~1,000 tokens | 1/day | Low — daily cadence, cache expires between runs |

### Expected Savings from Caching

For workflows that retain Anthropic models (WF2 and WF4):

**WF2 (1,000 calls):**
- System prompt: ~1,200 tokens per call = 1,200,000 tokens total
- Without caching: 1,200,000 × $3.00/MTok = $3.60
- With caching (90% reads): 120,000 × $3.00 + 1,080,000 × $0.30 = $0.36 + $0.32 = $0.68
- **Savings: ~$2.92 per 1,000 tickets**

**WF4 (300 calls):**
- System prompt: ~1,100 tokens per call = 330,000 tokens total
- Without caching: 330,000 × $3.00/MTok = $0.99
- With caching: ~$0.12
- **Savings: ~$0.87 per 1,000 tickets**

### Implementation

In n8n, enable prompt caching by adding the `cache_control` parameter to the system message in the Anthropic API call:

```json
{
  "system": [
    {
      "type": "text",
      "text": "Your system prompt here...",
      "cache_control": { "type": "ephemeral" }
    }
  ]
}
```

> **Note:** If WF1 or WF3 switch to non-Anthropic models, caching applies only to WF2 and WF4. OpenAI and Google also offer their own caching mechanisms — OpenAI automatic prompt caching provides 50% input discount and Google provides 75% discount on cached content.

---

## Max Tokens Right-Sizing

All 7 agents currently use `maxTokensToSample: 4096`. This is excessive for several tasks.

### Recommended Max Token Settings

| Workflow | Current | Recommended | Rationale |
|----------|---------|-------------|-----------|
| WF1: Triage | 4,096 | **1,024** | Classification output is a fixed JSON object (~200–400 tokens) |
| WF2: Solution | 4,096 | **3,072** | Solutions can be detailed but rarely exceed 2,500 tokens |
| WF3: Detection | 4,096 | **2,048** | Anomaly reports are structured and moderate length |
| WF4: Research | 4,096 | **4,096** | Research drafts can be comprehensive — keep as-is |
| WF5: Patterns | 4,096 | **2,048** | Pattern summaries are structured data |
| WF5: Articles | 4,096 | **4,096** | KB articles need full length — keep as-is |

### Impact

Right-sizing `maxTokensToSample` does not directly reduce cost (you pay for actual tokens generated, not the limit). However, it:

1. **Prevents runaway outputs** — A model that starts hallucinating or looping will stop sooner
2. **Reduces latency** — Lower limits signal expected response size, potentially improving time-to-first-token
3. **Improves reliability** — Constrains output to expected bounds

---

## Projected Cost Savings

### Cost Comparison Per 1,000 Tickets

| Workflow | Current Cost | Optimized Cost | Savings | Savings % |
|----------|-------------|---------------|---------|-----------|
| WF1: Triage | $16.50 | $0.55 | $15.95 | 97% |
| WF2: Solution | $16.50 | $13.08 | $3.42 | 21% |
| WF3: Detection | $23.76 | $0.49 | $23.27 | 98% |
| WF4: Research | $4.95 | $3.90 | $1.05 | 21% |
| WF5: Patterns | $0.50 | $0.02 | $0.48 | 96% |
| WF5: Articles | $0.50 | $0.25 | $0.25 | 50% |
| Embeddings | $0.02 | $0.02 | $0.00 | 0% |
| **Total** | **$62.73** | **$18.31** | **$44.42** | **71%** |

### Annual Projection (at 10,000 tickets/year)

| Metric | Current | Optimized |
|--------|---------|-----------|
| Annual LLM cost | ~$627 | ~$183 |
| Annual savings | — | **~$444** |
| Cost per ticket | $0.063 | $0.018 |

### Annual Projection (at 50,000 tickets/year)

| Metric | Current | Optimized |
|--------|---------|-----------|
| Annual LLM cost | ~$3,137 | ~$916 |
| Annual savings | — | **~$2,221** |
| Cost per ticket | $0.063 | $0.018 |

> **Note:** WF3 costs scale with time, not ticket volume (it runs every 15 min regardless). At higher volumes, per-ticket savings increase because WF1/WF2 dominate costs.

---

## Implementation Roadmap

### Phase 1: Quick Wins (Low Risk)

**Max tokens right-sizing**
- Update `maxTokensToSample` for WF1 (4096 → 1024), WF3 (4096 → 2048), WF5 patterns (4096 → 2048)
- Zero cost, no model change, immediate reliability improvement
- Test by running each workflow and verifying output is not truncated

**Prompt caching for WF2 and WF4**
- Add `cache_control: { type: "ephemeral" }` to system prompts
- No model change needed, backward compatible
- Monitor cache hit rates in token tracking

### Phase 2: Model Swaps (Medium Risk)

**WF1: Switch triage to gemini-2.0-flash or gpt-4o-mini**
1. Set up the alternative model credential in n8n
2. Run A/B test: Process 100 tickets through both current (Sonnet) and new model
3. Compare: classification accuracy, JSON validity rate, confidence score distribution
4. If accuracy >= 95% match, deploy new model
5. Keep Sonnet as fallback for edge cases (configurable via environment variable)

**WF3: Switch detection to gpt-4o-mini**
1. Same A/B approach — run 1 week of parallel analysis
2. Compare anomaly detection recall and precision
3. Deploy if detection quality is maintained

**WF5: Switch pattern analysis to gpt-4o-mini**
1. Run parallel daily analysis for 1 week
2. Compare trend detection and gap identification quality
3. Deploy when satisfied

### Phase 3: Batch Processing (Medium Risk)

**WF3: Implement batch detection**
1. Modify WF3 to submit batch API requests instead of synchronous calls
2. Add a polling sub-workflow that checks batch completion every 5 minutes
3. Process results and trigger alerts as before
4. Adjust detection cadence if needed (15 min → 30 min acceptable for batch)

**WF5: Implement batch learning**
1. Submit daily pattern analysis as batch request
2. Poll for completion
3. Submit article generation as second batch
4. Process and publish to Confluence

### Phase 4: Multi-Vendor Resilience

**Add fallback model support**
1. Create an environment variable `LLM_PROVIDER` per workflow
2. Implement a model router that selects the API based on provider
3. Configure automatic failover: if primary model returns 5xx, retry with fallback
4. Example: WF1 primary = gemini-2.0-flash, fallback = gpt-4o-mini, emergency = claude-haiku

---

## Risk Assessment

### Model Quality Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Triage accuracy drops with lighter model | Misrouted tickets, incorrect priority | A/B test with 100+ tickets before deploying; keep Sonnet as fallback |
| Detection misses anomalies | Delayed response to production issues | Run parallel detection for 1 week; compare recall rates |
| Pattern analysis misses trends | Incomplete learning cycle | Daily comparison during transition period |
| Solution quality varies across vendors | Customer satisfaction impact | WF2 stays on Sonnet — no change to customer-facing output |

### Operational Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Multi-vendor credential management | Increased complexity | Use n8n credential store; document all credentials |
| Batch API latency exceeds SLA | Delayed alerts from WF3 | Only batch non-time-critical workflows; keep real-time for WF1/WF2 |
| API outage at one vendor | Workflow failures | Implement fallback routing (Phase 4) |
| Prompt caching cache misses | Higher than expected costs | Monitor cache hit rates; ensure call frequency keeps cache warm |

### Model Recommendations Confidence

| Recommendation | Confidence | Evidence |
|----------------|------------|----------|
| WF1 → gemini-2.0-flash | High | Classification is a well-benchmarked task; structured JSON output |
| WF2 → Keep Sonnet | High | Customer-facing quality is paramount |
| WF3 → gpt-4o-mini + batch | High | Internal analytics with structured output; not time-critical |
| WF4 → Keep Sonnet | High | Complex research requiring strong reasoning |
| WF5 patterns → gpt-4o-mini | Medium-High | Trend detection is moderately complex; test thoroughly |
| WF5 articles → Sonnet batch | High | Quality content generation, batch adds pure savings |
| Embeddings → Keep as-is | High | Already optimal pricing at $0.02/MTok |

---

## Appendix: Vendor Batch API Reference

### Anthropic Message Batches API

```
POST https://api.anthropic.com/v1/messages/batches
```

- Max 10,000 requests per batch
- Results within 24 hours
- 50% discount on input and output tokens
- Poll status: `GET /v1/messages/batches/{batch_id}`
- Results: `GET /v1/messages/batches/{batch_id}/results`

### OpenAI Batch API

```
POST https://api.openai.com/v1/batches
```

- Upload requests as JSONL file
- Results within 24 hours
- 50% discount on all tokens
- Poll status: `GET /v1/batches/{batch_id}`

### Google Batch Prediction

- Available for Gemini models via Vertex AI
- 50% discount on input and output tokens
- Asynchronous processing

---

*LLM Cost Optimization Report v1.0 — January 2026*
