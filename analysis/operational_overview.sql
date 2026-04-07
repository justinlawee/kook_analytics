
-- Kook Operational Overview
-- Data source: KOOK_DATA.DBT_MODELS (dbt-transformed tables)

-- ============================================================
-- 1. EXECUTIVE SUMMARY
-- ============================================================

SELECT
  COUNT(*) AS total_orders,
  ROUND(SUM(total_amount), 2) AS total_revenue,
  ROUND(SUM(net_revenue), 2) AS total_net_revenue,
  ROUND(AVG(total_amount), 2) AS avg_order_value,
  ROUND(SUM(discount_amount), 2) AS total_discounts,
  ROUND(SUM(refunded_amount), 2) AS total_refunds,
  COUNT(DISTINCT customer_email) AS unique_customers,
  MIN(created_at) AS first_order_date,
  MAX(created_at) AS last_order_date
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS;

-- ============================================================
-- 2. REVENUE TRENDS
-- ============================================================

SELECT
  order_month AS month,
  ROUND(SUM(total_amount), 2) AS revenue,
  ROUND(SUM(net_revenue), 2) AS net_revenue,
  COUNT(*) AS orders,
  ROUND(AVG(total_amount), 2) AS avg_order_value,
  ROUND(SUM(discount_amount), 2) AS discounts_given
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
GROUP BY order_month
ORDER BY order_month;

-- ============================================================
-- 3. PRODUCT PERFORMANCE
-- ============================================================

SELECT
  product_name,
  total_units_sold AS units_sold,
  times_ordered,
  total_revenue AS product_revenue,
  avg_unit_price,
  first_sold_at,
  last_sold_at
FROM KOOK_DATA.DBT_MODELS.DIM_PRODUCTS
ORDER BY total_revenue DESC;

-- ============================================================
-- 4. SALES CHANNELS
-- ============================================================

SELECT
  sales_channel,
  ROUND(SUM(total_amount), 2) AS revenue,
  COUNT(*) AS orders,
  ROUND(AVG(total_amount), 2) AS avg_order_value
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE sales_channel IS NOT NULL AND sales_channel != ''
GROUP BY sales_channel
ORDER BY revenue DESC;

SELECT
  order_month AS month,
  sales_channel,
  ROUND(SUM(total_amount), 2) AS revenue
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE sales_channel IS NOT NULL AND sales_channel != ''
GROUP BY order_month, sales_channel
ORDER BY order_month, revenue DESC;

-- ============================================================
-- 5. GEOGRAPHY
-- ============================================================

SELECT
  billing_state AS state,
  billing_country AS country,
  ROUND(SUM(total_amount), 2) AS revenue,
  COUNT(*) AS orders,
  COUNT(DISTINCT customer_email) AS unique_customers
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE billing_state IS NOT NULL AND billing_state != ''
GROUP BY billing_state, billing_country
ORDER BY revenue DESC;

SELECT
  billing_city AS city,
  billing_state AS state,
  ROUND(SUM(total_amount), 2) AS revenue,
  COUNT(*) AS orders
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE billing_city IS NOT NULL AND billing_city != ''
GROUP BY billing_city, billing_state
ORDER BY revenue DESC
LIMIT 20;

-- ============================================================
-- 6. CUSTOMER ANALYSIS
-- ============================================================

SELECT
  customer_segment,
  COUNT(*) AS customers,
  ROUND(SUM(lifetime_revenue), 2) AS total_revenue,
  ROUND(AVG(lifetime_revenue), 2) AS avg_ltv,
  ROUND(AVG(lifetime_orders), 1) AS avg_orders
FROM KOOK_DATA.DBT_MODELS.DIM_CUSTOMERS
GROUP BY customer_segment
ORDER BY total_revenue DESC;

SELECT
  customer_email,
  customer_name,
  customer_segment,
  lifetime_orders AS orders,
  lifetime_revenue AS total_spent,
  avg_order_value,
  first_order_at,
  last_order_at
FROM KOOK_DATA.DBT_MODELS.DIM_CUSTOMERS
ORDER BY lifetime_revenue DESC
LIMIT 15;

-- ============================================================
-- 7. DISCOUNT & PROMO ANALYSIS
-- ============================================================

SELECT
  discount_code,
  COUNT(*) AS orders,
  ROUND(SUM(total_amount), 2) AS revenue,
  ROUND(SUM(discount_amount), 2) AS total_discount_given,
  ROUND(AVG(total_amount), 2) AS avg_order_value
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE has_discount
GROUP BY discount_code
ORDER BY revenue DESC;

-- ============================================================
-- 8. FULFILLMENT & OPERATIONS
-- ============================================================

SELECT
  fulfillment_status,
  financial_status,
  COUNT(*) AS orders,
  ROUND(SUM(total_amount), 2) AS revenue
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
GROUP BY fulfillment_status, financial_status
ORDER BY orders DESC;

SELECT
  shipping_method,
  COUNT(*) AS orders,
  ROUND(SUM(shipping_amount), 2) AS total_shipping_revenue,
  ROUND(AVG(shipping_amount), 2) AS avg_shipping_cost
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE shipping_method IS NOT NULL AND shipping_method != ''
GROUP BY shipping_method
ORDER BY orders DESC;

-- ============================================================
-- 9. REFUND & CANCELLATION ANALYSIS
-- ============================================================

SELECT
  order_month AS month,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN is_refunded THEN 1 ELSE 0 END) AS refunded_orders,
  ROUND(SUM(refunded_amount), 2) AS refund_amount,
  ROUND(100.0 * SUM(CASE WHEN is_refunded THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS refund_rate_pct,
  SUM(CASE WHEN is_cancelled THEN 1 ELSE 0 END) AS cancelled_orders
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
GROUP BY order_month
ORDER BY order_month;

-- ============================================================
-- 10. COHORT ANALYSIS
-- ============================================================

SELECT
  acquisition_cohort,
  customer_segment,
  COUNT(*) AS customers,
  ROUND(AVG(lifetime_revenue), 2) AS avg_ltv,
  ROUND(AVG(lifetime_orders), 1) AS avg_orders
FROM KOOK_DATA.DBT_MODELS.DIM_CUSTOMERS
GROUP BY acquisition_cohort, customer_segment
ORDER BY acquisition_cohort, customer_segment;
