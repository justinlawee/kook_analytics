-- Kook Sales Spike Analysis: What drove the July-August 2025 surge?
-- Data source: KOOK_DATA.DBT_MODELS (dbt-transformed tables)

-- 1. Monthly Revenue Trend (2025)
SELECT
  order_month AS month,
  ROUND(SUM(total_amount), 2) AS total_revenue,
  ROUND(SUM(net_revenue), 2) AS net_revenue,
  COUNT(*) AS orders
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE YEAR(created_at) = 2025
GROUP BY order_month
ORDER BY order_month;

-- 2. Revenue by Sales Channel by Month (2025)
SELECT
  order_month AS month,
  sales_channel,
  ROUND(SUM(total_amount), 2) AS total_revenue
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE YEAR(created_at) = 2025
GROUP BY order_month, sales_channel
ORDER BY order_month, total_revenue DESC NULLS LAST;

-- 3. Top Products by Revenue (Jul-Aug 2025)
SELECT
  product_name,
  COUNT(*) AS times_sold,
  SUM(line_item_quantity) AS units_sold,
  ROUND(SUM(line_item_revenue), 2) AS total_revenue
FROM KOOK_DATA.DBT_MODELS.FCT_ORDER_ITEMS
WHERE created_at >= '2025-07-01' AND created_at < '2025-09-01'
GROUP BY product_name
ORDER BY total_revenue DESC;

-- 4. Revenue by Geography (Jul-Aug 2025)
SELECT
  billing_state,
  billing_country,
  ROUND(SUM(total_amount), 2) AS total_revenue,
  COUNT(*) AS orders
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE created_at >= '2025-07-01' AND created_at < '2025-09-01'
GROUP BY billing_state, billing_country
ORDER BY total_revenue DESC NULLS LAST;

-- 5. Discount Code Impact (Jul-Aug 2025)
SELECT
  discount_code,
  ROUND(SUM(total_amount), 2) AS total_revenue,
  COUNT(*) AS total_orders
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE created_at >= '2025-07-01' AND created_at < '2025-09-01'
GROUP BY discount_code
ORDER BY total_revenue DESC NULLS LAST;
