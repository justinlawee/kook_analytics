-- Kook Strategic Analysis
-- Growth, retention, and product strategy insights
-- Data source: KOOK_DATA.DBT_MODELS (dbt-transformed tables)

-- ============================================================
-- 1. COHORT RETENTION: Do customers come back?
-- ============================================================

WITH first_orders AS (
    SELECT
        customer_email,
        DATE_TRUNC('MONTH', MIN(created_at)) AS cohort_month
    FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
    WHERE customer_email IS NOT NULL AND customer_email != ''
    GROUP BY customer_email
),
order_months AS (
    SELECT DISTINCT
        o.customer_email,
        DATE_TRUNC('MONTH', o.created_at) AS order_month
    FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS o
    WHERE o.customer_email IS NOT NULL AND o.customer_email != ''
)
SELECT
    f.cohort_month,
    COUNT(DISTINCT f.customer_email) AS cohort_size,
    COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 0 THEN om.customer_email END) AS month_0,
    COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 1 THEN om.customer_email END) AS month_1,
    COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 2 THEN om.customer_email END) AS month_2,
    COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 3 THEN om.customer_email END) AS month_3,
    COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 6 THEN om.customer_email END) AS month_6,
    COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 12 THEN om.customer_email END) AS month_12
FROM first_orders f
LEFT JOIN order_months om ON f.customer_email = om.customer_email
GROUP BY f.cohort_month
ORDER BY f.cohort_month;

-- ============================================================
-- 2. TIME TO SECOND PURCHASE
-- ============================================================

WITH ordered AS (
    SELECT
        customer_email,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY customer_email ORDER BY created_at) AS order_num
    FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
    WHERE customer_email IS NOT NULL AND customer_email != ''
),
second_purchase AS (
    SELECT
        o1.customer_email,
        o1.created_at AS first_order,
        o2.created_at AS second_order,
        DATEDIFF('DAY', o1.created_at, o2.created_at) AS days_to_second
    FROM ordered o1
    JOIN ordered o2 ON o1.customer_email = o2.customer_email AND o2.order_num = 2
    WHERE o1.order_num = 1
)
SELECT
    CASE
        WHEN days_to_second <= 7 THEN '0-7 days'
        WHEN days_to_second <= 14 THEN '8-14 days'
        WHEN days_to_second <= 30 THEN '15-30 days'
        WHEN days_to_second <= 60 THEN '31-60 days'
        WHEN days_to_second <= 90 THEN '61-90 days'
        WHEN days_to_second <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END AS days_bucket,
    COUNT(*) AS customers,
    ROUND(AVG(days_to_second), 0) AS avg_days
FROM second_purchase
GROUP BY days_bucket
ORDER BY MIN(days_to_second);

-- ============================================================
-- 3. PRODUCT ATTACH RATE: What's bought together?
-- ============================================================

WITH order_products AS (
    SELECT DISTINCT order_id, product_name
    FROM KOOK_DATA.DBT_MODELS.FCT_ORDER_ITEMS
    WHERE product_name IS NOT NULL
),
pairs AS (
    SELECT
        a.product_name AS product_a,
        b.product_name AS product_b,
        COUNT(DISTINCT a.order_id) AS times_bought_together
    FROM order_products a
    JOIN order_products b ON a.order_id = b.order_id AND a.product_name < b.product_name
    GROUP BY a.product_name, b.product_name
)
SELECT
    product_a,
    product_b,
    times_bought_together,
    ROUND(100.0 * times_bought_together / (SELECT COUNT(DISTINCT order_id) FROM KOOK_DATA.DBT_MODELS.FCT_ORDER_ITEMS), 1) AS pct_of_orders
FROM pairs
ORDER BY times_bought_together DESC
LIMIT 15;

-- ============================================================
-- 4. SOLAR MOISTURIZER LAUNCH TRACKING (April 2025+)
-- ============================================================

SELECT
    order_month AS month,
    COUNT(*) AS units_ordered,
    SUM(line_item_quantity) AS total_units,
    ROUND(SUM(line_item_revenue), 2) AS revenue,
    COUNT(DISTINCT customer_email) AS unique_buyers
FROM KOOK_DATA.DBT_MODELS.FCT_ORDER_ITEMS
WHERE product_name ILIKE '%SOLAR MOISTURIZER%' OR product_name ILIKE '%TINTED SOLAR%'
GROUP BY order_month
ORDER BY order_month;

-- ============================================================
-- 5. INFLUENCER / DISCOUNT CODE LTV
-- Which codes drive repeat buyers, not just first orders?
-- ============================================================

WITH first_order_code AS (
    SELECT
        customer_email,
        discount_code,
        created_at AS first_order_at
    FROM (
        SELECT
            customer_email,
            discount_code,
            created_at,
            ROW_NUMBER() OVER (PARTITION BY customer_email ORDER BY created_at) AS rn
        FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
        WHERE customer_email IS NOT NULL AND customer_email != ''
    )
    WHERE rn = 1 AND discount_code IS NOT NULL AND discount_code != ''
)
SELECT
    fc.discount_code AS acquisition_code,
    COUNT(DISTINCT fc.customer_email) AS customers_acquired,
    COUNT(DISTINCT CASE WHEN dc.lifetime_orders > 1 THEN fc.customer_email END) AS repeat_customers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN dc.lifetime_orders > 1 THEN fc.customer_email END)
        / NULLIF(COUNT(DISTINCT fc.customer_email), 0), 1) AS repeat_rate_pct,
    ROUND(AVG(dc.lifetime_revenue), 2) AS avg_customer_ltv,
    ROUND(AVG(dc.lifetime_orders), 1) AS avg_lifetime_orders
FROM first_order_code fc
JOIN KOOK_DATA.DBT_MODELS.DIM_CUSTOMERS dc ON fc.customer_email = dc.customer_email
GROUP BY fc.discount_code
HAVING COUNT(DISTINCT fc.customer_email) >= 2
ORDER BY avg_customer_ltv DESC;

-- ============================================================
-- 6. AMAZON VS WEB: Channel comparison
-- ============================================================

SELECT
    sales_channel,
    COUNT(*) AS orders,
    ROUND(SUM(total_amount), 2) AS revenue,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    COUNT(DISTINCT customer_email) AS unique_customers,
    ROUND(SUM(total_amount) / NULLIF(COUNT(DISTINCT customer_email), 0), 2) AS revenue_per_customer,
    ROUND(SUM(discount_amount), 2) AS total_discounts,
    ROUND(100.0 * SUM(CASE WHEN has_discount THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS discount_usage_pct
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
WHERE sales_channel IN ('web', 'amazon')
GROUP BY sales_channel;

-- ============================================================
-- 7. POS EVENT FOLLOW-UP: Do event buyers return online?
-- ============================================================

WITH pos_customers AS (
    SELECT DISTINCT customer_email
    FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
    WHERE sales_channel = 'pos'
      AND customer_email IS NOT NULL AND customer_email != ''
)
SELECT
    COUNT(DISTINCT pc.customer_email) AS total_pos_customers,
    COUNT(DISTINCT CASE WHEN o.sales_channel != 'pos' THEN pc.customer_email END) AS returned_on_other_channel,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.sales_channel != 'pos' THEN pc.customer_email END)
        / NULLIF(COUNT(DISTINCT pc.customer_email), 0), 1) AS conversion_rate_pct,
    ROUND(AVG(CASE WHEN o.sales_channel != 'pos' THEN o.total_amount END), 2) AS avg_followup_order_value
FROM pos_customers pc
LEFT JOIN KOOK_DATA.DBT_MODELS.FCT_ORDERS o
    ON pc.customer_email = o.customer_email AND o.sales_channel != 'pos';

-- ============================================================
-- 8. MONTHLY GROWTH RATE
-- ============================================================

WITH monthly AS (
    SELECT
        order_month AS month,
        ROUND(SUM(total_amount), 2) AS revenue,
        COUNT(*) AS orders
    FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
    GROUP BY order_month
)
SELECT
    month,
    revenue,
    orders,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1) AS revenue_growth_pct,
    ROUND(100.0 * (orders - LAG(orders) OVER (ORDER BY month))
        / NULLIF(LAG(orders) OVER (ORDER BY month), 0), 1) AS order_growth_pct
FROM monthly
ORDER BY month;

-- ============================================================
-- 9. GEOGRAPHIC EXPANSION: New states over time
-- ============================================================

WITH first_state_order AS (
    SELECT
        billing_state,
        billing_country,
        DATE_TRUNC('MONTH', MIN(created_at)) AS first_seen_month
    FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
    WHERE billing_state IS NOT NULL AND billing_state != ''
    GROUP BY billing_state, billing_country
)
SELECT
    first_seen_month,
    COUNT(*) AS new_states_added,
    LISTAGG(billing_state || ' (' || billing_country || ')', ', ') WITHIN GROUP (ORDER BY billing_state) AS states
FROM first_state_order
GROUP BY first_seen_month
ORDER BY first_seen_month;

-- ============================================================
-- 10. PRICE SENSITIVITY: Discount impact on volume
-- ============================================================

SELECT
    CASE
        WHEN NOT has_discount THEN 'No discount'
        WHEN discount_amount / NULLIF(subtotal + discount_amount, 0) <= 0.10 THEN '1-10%'
        WHEN discount_amount / NULLIF(subtotal + discount_amount, 0) <= 0.20 THEN '11-20%'
        WHEN discount_amount / NULLIF(subtotal + discount_amount, 0) <= 0.30 THEN '21-30%'
        ELSE '31%+'
    END AS effective_discount_tier,
    COUNT(*) AS orders,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(AVG(total_units), 1) AS avg_units_per_order,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(SUM(discount_amount), 2) AS total_discount_cost
FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS
GROUP BY effective_discount_tier
ORDER BY effective_discount_tier;
