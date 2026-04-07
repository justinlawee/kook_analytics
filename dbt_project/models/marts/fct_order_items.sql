SELECT
    order_id,
    product_name,
    product_sku,
    vendor,
    line_item_quantity,
    line_item_price,
    line_item_compare_price,
    line_item_discount,
    line_item_fulfillment_status,
    line_item_revenue,
    created_at,
    customer_email,
    sales_channel,
    discount_code,
    billing_state,
    billing_country,
    DATE_TRUNC('MONTH', created_at) AS order_month
FROM {{ ref('int_order_items') }}
