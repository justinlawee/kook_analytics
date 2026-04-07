SELECT
    customer_email,
    customer_name,
    lifetime_orders,
    lifetime_revenue,
    avg_order_value,
    first_order_at,
    last_order_at,
    accepts_marketing,
    customer_segment,
    acquisition_cohort
FROM {{ ref('int_customers') }}
