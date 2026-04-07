WITH source AS (
    SELECT * FROM {{ source('shopify', 'kook_orders') }}
)

SELECT
    ID AS order_id,
    TRY_CAST(CREATED_AT AS TIMESTAMP) AS created_at,
    TRY_CAST(PAID_AT AS TIMESTAMP) AS paid_at,
    TRY_CAST(FULFILLED_AT AS TIMESTAMP) AS fulfilled_at,
    TRY_CAST(CANCELLED_AT AS TIMESTAMP) AS cancelled_at,

    NAME AS order_name,
    EMAIL AS customer_email,
    BILLING_NAME AS customer_name,
    FINANCIAL_STATUS AS financial_status,
    FULFILLMENT_STATUS AS fulfillment_status,
    ACCEPTS_MARKETING AS accepts_marketing,
    CURRENCY AS currency,

    TRY_CAST(SUBTOTAL AS DECIMAL(38,2)) AS subtotal,
    TRY_CAST(SHIPPING AS DECIMAL(38,2)) AS shipping_amount,
    TRY_CAST(TAXES AS DECIMAL(38,2)) AS tax_amount,
    TRY_CAST(TOTAL AS DECIMAL(38,2)) AS total_amount,
    TRY_CAST(DISCOUNT_AMOUNT AS DECIMAL(38,2)) AS discount_amount,
    TRY_CAST(REFUNDED_AMOUNT AS DECIMAL(38,2)) AS refunded_amount,
    CASE
        WHEN DISCOUNT_CODE IN ('failed delivery', 'content creator', 'Belize SYB Trip', 'Launch party', 'retail', 'stockist discount') THEN NULL
        ELSE DISCOUNT_CODE
    END AS discount_code,
    DISCOUNT_CODE AS discount_code_raw,

    LINEITEM_NAME AS product_name,
    LINEITEM_SKU AS product_sku,
    TRY_CAST(LINEITEM_QUANTITY AS INT) AS line_item_quantity,
    TRY_CAST(LINEITEM_PRICE AS DECIMAL(38,2)) AS line_item_price,
    TRY_CAST(LINEITEM_COMPARE_AT_PRICE AS DECIMAL(38,2)) AS line_item_compare_price,
    TRY_CAST(LINEITEM_DISCOUNT AS DECIMAL(38,2)) AS line_item_discount,
    LINEITEM_FULFILLMENT_STATUS AS line_item_fulfillment_status,
    VENDOR AS vendor,

    SOURCE AS sales_channel,
    PAYMENT_METHOD AS payment_method,
    SHIPPING_METHOD AS shipping_method,
    RISK_LEVEL AS risk_level,
    LOCATION AS store_location,
    TAGS AS order_tags,

    BILLING_CITY AS billing_city,
    BILLING_PROVINCE AS billing_state,
    BILLING_PROVINCE_NAME AS billing_state_name,
    BILLING_COUNTRY AS billing_country,
    BILLING_ZIP AS billing_zip,

    SHIPPING_CITY AS shipping_city,
    SHIPPING_PROVINCE AS shipping_state,
    SHIPPING_PROVINCE_NAME AS shipping_state_name,
    SHIPPING_COUNTRY AS shipping_country,
    SHIPPING_ZIP AS shipping_zip

FROM source
WHERE ID IS NOT NULL
