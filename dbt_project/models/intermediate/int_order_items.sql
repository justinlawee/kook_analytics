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
    ROUND(line_item_price * line_item_quantity, 2) AS line_item_revenue,
    created_at,
    customer_email,
    sales_channel,
    discount_code,
    billing_state,
    billing_country
FROM {{ ref('stg_orders') }}
WHERE product_name IS NOT NULL
