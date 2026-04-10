#  🌊 KOOK Analytics (Snowflake + dbt + Streamlit)

This project builds a complete e-commerce analytics pipeline for [KOOK](https://gotkook.com) — an ocean-first cosmetics line for surfers, divers, and water lovers. Founded by Christina Kuklinski and Justin Lawee in Los Angeles.

It ingests live Shopify order data into Snowflake, transforms it with dbt into clean, typed analytics models, and surfaces insights through an interactive Streamlit dashboard — demonstrating what a productized DTC analytics workflow looks like inside the modern data stack.

## 🪸 About KOOK

KOOK makes reef-safe hair & skin care designed for 8 hours of hardcore ocean exposure. Every product is made in Los Angeles, tested in real ocean conditions, and every purchase plants a mangrove through their partnership with [Seatrees](https://www.seatrees.org/) in Baja's Laguna San Ignacio — a UNESCO World Heritage Site.

**Product line:** Pre-Swim Hair Mask, Solar Moisturizer, Post-Swim Conditioner, Ocean Mineral Shampoo, Reef-Safe Sunscreen SPF 30, and more.

## 💪🏼 What This Project Can Do

The analytics pipeline enables a variety of high-impact use cases for a growing DTC brand:

**Revenue & Operations Monitoring**
Track monthly revenue, order volume, AOV, refund rates, and fulfillment status in real time.

**Customer Intelligence**
Segment customers by lifetime value (one-time, returning, loyal, VIP), track cohort retention, and measure time-to-second-purchase.

**Product Strategy**
Identify hero products, track new product launches (Solar Moisturizer), and discover what products are frequently bought together.

**Channel & Geo Analysis**
Compare Web vs Amazon vs POS vs Wholesale performance, and map revenue by state and city.

**Marketing ROI**
Measure which influencer discount codes drive not just first orders, but repeat customers and long-term LTV.

## 📊 Live Streamlit Dashboard

**Note:** The dashboard runs natively inside Snowflake and requires account access. A screenshot is included below for reference.

5-tab interactive dashboard with sidebar filters (date range, channel, state):
- **Overview** — KPI cards + monthly revenue/order trend chart
- **Products** — Top products by revenue, product attach rates
- **Customers** — Segment breakdown, cohort retention heatmap, top 15 customers
- **Channels & Geo** — Channel comparison, Amazon vs Web deep dive, revenue by state
- **Promos & Growth** — Discount code performance, influencer LTV, MoM growth rate

## 🧱 Project Stack & Tools

| Component | Tool Used |
|---|---|
| Data Warehouse | Snowflake (`KOOK_DATA`) |
| Data Ingestion | Shopify Connector (Marketplace Native App) |
| Modeling | dbt (staging → intermediate → marts) |
| Dashboard | Streamlit in Snowflake (native) |
| Semantic Layer | Snowflake Semantic Views (for Cortex Analyst) |
| AI Assistant | AGENTS.md for Cortex Code context |

## 🏢 Architecture

```
Shopify Store → Snowflake Connector → Raw Table (all VARCHAR)
                                          ↓
                                    dbt Staging (typed, cleaned)
                                          ↓
                                    dbt Intermediate (aggregated)
                                          ↓
                                    dbt Marts (fact + dimension tables)
                                          ↓
                                    Streamlit Dashboard + SQL Analysis Files
```

## ⚙️ dbt Models

| Layer | Model | Materialized | Description |
|---|---|---|---|
| Staging | `stg_orders` | View | Typed columns, cleaned discount codes, proper naming |
| Intermediate | `int_customers` | View | Customer-level aggregation with segmentation |
| Intermediate | `int_order_items` | View | Line-item grain with computed revenue |
| Marts | `fct_orders` | Table | Order facts: net revenue, discount/refund flags, time dims |
| Marts | `fct_order_items` | Table | Line-item facts with product, channel, geography |
| Marts | `dim_customers` | Table | Customer LTV, segment (one_time/returning/loyal/vip), cohort |
| Marts | `dim_products` | Table | Product catalog with total revenue, units sold, avg price |

All models include data tests (uniqueness, not_null) and are fully typed — no more `TRY_CAST` in downstream queries.

## 📉 SQL Analysis Files

| File | Purpose |
|---|---|
| `operational_overview.sql` | 10-section operational dashboard: exec summary, revenue trends, products, channels, geography, customers, discounts, fulfillment, refunds, cohorts |
| `strategic_analysis.sql` | 10-section growth & retention: cohort retention, time to 2nd purchase, product attach rates, Solar Moisturizer launch tracking, influencer LTV, Amazon vs Web, POS event follow-up, MoM growth, geographic expansion, price sensitivity |
| `sales_spike_analysis.sql` | July 2025 revenue spike deep dive (channel, product, geography, discount breakdown) |

## 💡 Key Findings

- **Hero product:** PRE-SWIM HAIR MASK drives 40-60% of total revenue at $44/unit
- **Biggest month:** July 2025 — driven by a launch event + wholesale push + coordinated influencer campaign
- **Primary market:** California (33% of revenue), followed by FL, NY, TX, HI
- **Channels:** Web is primary (~60%); Amazon since April 2024; POS spikes during events; wholesale via draft orders
- **Seasonality:** Summer months stronger (ocean sports); Nov-Dec holiday gifting bump
- **Customer mix:** Majority are one-time buyers — retention and repeat purchase are the key growth levers

## 📌 How to Run This Project

**Step 1:** Ensure Shopify Connector is syncing data to `KOOK_DATA.PUBLIC.KOOK_ORDERS`

**Step 2:** Run dbt transformations
```bash
dbt run --project-dir /kook_analysis/dbt_project
```

**Step 3:** Run dbt tests
```bash
dbt test --project-dir /kook_analysis/dbt_project
```

**Step 4:** Open the Streamlit dashboard in Snowsight → Streamlit → KOOK_DASHBOARD

**Step 5:** Redeploy Streamlit after edits
```sql
COPY FILES INTO @KOOK_DATA.DBT_MODELS.STREAMLIT_STAGE
FROM 'snow://workspace/USER$JBORENSTEINLAWEE.PUBLIC.DEFAULT$/versions/live/kook_analysis'
FILES = ('streamlit_app.py', 'environment.yml');
```

## 🗂️ Data Source

This project uses live Shopify order data from [gotkook.com](https://gotkook.com), ingested via the Shopify Connector Native App on Snowflake Marketplace. The dataset includes:

- Order transactions since April 2024
- Line-item product details with pricing
- Customer billing and shipping addresses
- Discount codes and payment methods
- Fulfillment and financial status

## ⚠️ Data Disclaimer

This project uses **real, private Shopify order data** from KOOK. The underlying data is not included in this repository and the Streamlit dashboard requires Snowflake account access.

## 📁 Project Structure

```
kook_analysis/
├── dbt_project/
│   ├── models/
│   │   ├── staging/
│   │   │   ├── stg_orders.sql
│   │   │   └── sources.yml
│   │   ├── intermediate/
│   │   │   ├── int_customers.sql
│   │   │   └── int_order_items.sql
│   │   ├── marts/
│   │   │   ├── fct_orders.sql
│   │   │   ├── fct_order_items.sql
│   │   │   ├── dim_customers.sql
│   │   │   └── dim_products.sql
│   │   └── schema.yml
│   ├── dbt_project.yml
│   └── profiles.yml
├── analysis/
│   ├── operational_overview.sql
│   ├── strategic_analysis.sql
│   └── sales_spike_analysis.sql
├── streamlit/
│   ├── streamlit_app.py
│   └── environment.yml
├── AGENTS.md
├── README.md
└── .gitignore
```

## GitHub Metadata

- **Author:** Justin Borenstein-Lawee
- **Last Updated:** April 2026
- **Topics:** `snowflake` `dbt` `streamlit` `shopify` `ecommerce-analytics` `dtc`
