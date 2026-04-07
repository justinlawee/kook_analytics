WITH items AS (
    SELECT * FROM {{ ref('int_order_items') }}
)

SELECT
    product_name,
    product_sku,
    vendor,
    COUNT(DISTINCT order_id) AS times_ordered,
    SUM(line_item_quantity) AS total_units_sold,
    ROUND(SUM(line_item_revenue), 2) AS total_revenue,
    ROUND(AVG(line_item_price), 2) AS avg_unit_price,
    MIN(created_at) AS first_sold_at,
    MAX(created_at) AS last_sold_at
FROM items
GROUP BY product_name, product_sku, vendor
