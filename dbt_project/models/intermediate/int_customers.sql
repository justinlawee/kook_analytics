WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customer_stats AS (
    SELECT
        customer_email,
        MAX(customer_name) AS customer_name,
        COUNT(DISTINCT order_id) AS lifetime_orders,
        ROUND(SUM(total_amount), 2) AS lifetime_revenue,
        ROUND(AVG(total_amount), 2) AS avg_order_value,
        MIN(created_at) AS first_order_at,
        MAX(created_at) AS last_order_at,
        MAX(CASE WHEN accepts_marketing = 'yes' THEN TRUE ELSE FALSE END) AS accepts_marketing
    FROM orders
    WHERE customer_email IS NOT NULL AND customer_email != ''
    GROUP BY customer_email
)

SELECT
    customer_email,
    customer_name,
    lifetime_orders,
    lifetime_revenue,
    avg_order_value,
    first_order_at,
    last_order_at,
    accepts_marketing,
    CASE
        WHEN lifetime_orders = 1 THEN 'one_time'
        WHEN lifetime_orders BETWEEN 2 AND 3 THEN 'returning'
        WHEN lifetime_orders BETWEEN 4 AND 5 THEN 'loyal'
        ELSE 'vip'
    END AS customer_segment,
    DATE_TRUNC('MONTH', first_order_at) AS acquisition_cohort
FROM customer_stats
