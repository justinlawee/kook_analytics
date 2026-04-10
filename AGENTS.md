# Kook Analysis Project

## Project Overview
Shopify e-commerce analytics for KOOK — an ocean-first hair & skin care brand for surfers, divers, and water lovers. Data flows from Shopify into Snowflake via a connector, then gets transformed by dbt into clean analytics tables.

## Brand Context

### About KOOK
- **Website:** gotkook.com
- **Founded by:** Christina Kuklinski (master scuba diver, 15,000+ hours underwater) with co-founder Justin Lawee (certified Dive Master)
- **HQ:** Los Angeles — all products designed, filled, printed, and packed within 50 miles of LA
- **Tagline:** "Reef-safe essentials that care for both body and sea"
- **Brand name meaning:** KOOK = badge of honor for those wildly passionate about chasing waves and adventure
- **Mission:** High-performance, reef-safe products designed for 8 hours of hardcore ocean exposure — protecting from sun, salt, surf, and sweat without harming reefs
- **Founder background:** Decade in brand strategy and consumer insights at Unilever, L'Oreal, and Wella; Tufts University (Sociology, Entrepreneurial Leadership, Mass Media Studies)

### Product Line
| Product | Price | Notes |
|---|---|---|
| PRE-SWIM HAIR MASK | $44 |
| SOLAR MOISTURIZER | $36 | Launched April 2026 |
| Ocean Protection Duo | $72 (sale from $80) | Bundle |
| Recycled Tote Bag | $25 | Merch |

### Target Audience
- Surfers, scuba divers, swimmers, ocean lovers
- All hair types
- Environmentally conscious consumers who care about reef safety

### Impact & Sustainability
- Every purchase plants a mangrove through partnership with Seatrees
- Mangroves planted in Baja's Laguna San Ignacio (UNESCO World Heritage Site)
- Reef-safe certified ingredients
- Supports local communities in conservation areas

### Marketing & Growth Channels
- Ambassador/influencer program (SOPHIA20, ROCIO20, INFLUENCER30, GETSALTY, etc.)
- Newsletter signup with $10 off first order (WELCOME10)
- Instagram-heavy social media presence
- In-person events (Launch party POS sales)
- Wholesale/B2B via draft orders
- Amazon marketplace
- Affiliate program

## Data Architecture

### Raw Source
- **Table:** `KOOK_DATA.PUBLIC.KOOK_ORDERS`
- All columns are VARCHAR — never query this directly, use the dbt models instead

### dbt Models (KOOK_DATA.DBT_MODELS)
| Model | Type | Description |
|---|---|---|
| `FCT_ORDERS` | Table | Order-level facts: revenue, net revenue, discounts, refunds, flags |
| `FCT_ORDER_ITEMS` | Table | Line-item level: product, quantity, revenue, channel, geography |
| `DIM_CUSTOMERS` | Table | Customer LTV, segment (one_time/returning/loyal/vip), acquisition cohort |
| `DIM_PRODUCTS` | Table | Product catalog with total revenue, units sold, avg price |

### Semantic Views
- `KOOK_DATA.PUBLIC.KOOK_ASSISTANT_SV` — works against raw table, use for Cortex Analyst queries
- `KOOK_DATA.PUBLIC.KOOK_ORDERS_SV` — broken (references missing KOOK_DATA2 table), do not use

## dbt Project
- **Location:** `/kook_analysis/dbt_project/`
- **Profile target:** `KOOK_DATA.DBT_MODELS` on `COMPUTE_WH`
- **Run:** `dbt run --project-dir /kook_analysis/dbt_project`
- **Test:** `dbt test --project-dir /kook_analysis/dbt_project`

## Key Data Insights
- Hero product: PRE-SWIM HAIR MASK (typically 40-60% of revenue)
- Sales channels: web (primary), amazon, shopify_draft_order (wholesale), pos (events)
- Primary market: California, then Florida, New York, Texas
- Discount codes include influencer codes (SOPHIA20, ROCIO20, INFLUENCER30) and campaign codes (Launch party, SUMMER25, KOOKHEAD)
- Biggest revenue month: July 2025 — driven by a launch event + wholesale push + influencer campaign
- Solar Moisturizer launched ~April 2025
- Data starts April 2024
- Seasonality: summer months tend stronger (ocean sports); Nov-Dec holiday gifting bump

## SQL Files
- `/kook_analysis/operational_overview.sql` — 10-section operational dashboard (revenue, products, channels, geography, customers, discounts, fulfillment, refunds, cohorts)
- `/kook_analysis/strategic_analysis.sql` — growth & retention insights (cohort retention, time to second purchase, product attach rates, influencer LTV, channel comparison, POS follow-up, monthly growth, geographic expansion, price sensitivity)
- `/kook_analysis/sales_spike_analysis.sql` — July-August 2025 spike deep dive

## Streamlit Dashboard
- **App:** `KOOK_DATA.DBT_MODELS.KOOK_DASHBOARD`
- **Source:** `/kook_analysis/streamlit_app.py`
- **Stage:** `@KOOK_DATA.DBT_MODELS.STREAMLIT_STAGE`
- **To redeploy after edits:** Run `COPY FILES INTO @KOOK_DATA.DBT_MODELS.STREAMLIT_STAGE FROM 'snow://workspace/USER$JBORENSTEINLAWEE.PUBLIC.DEFAULT$/versions/live/kook_analysis' FILES = ('streamlit_app.py', 'environment.yml');`
- 5 tabs: Overview, Products, Customers, Channels & Geo, Promos & Growth
- Sidebar filters: date range, sales channel, state

## Conventions
- Always use fully qualified table names: `KOOK_DATA.DBT_MODELS.<table>`
- Prefer dbt models over raw source for all analysis
- Use `net_revenue` (total minus refunds) for true revenue metrics
- Use `has_discount` and `is_refunded` boolean flags instead of checking for NULLs
