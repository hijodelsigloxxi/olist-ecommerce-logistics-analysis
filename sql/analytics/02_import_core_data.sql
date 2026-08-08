-- ============================================================
-- 02_import_analytics_tables.sql
-- Importación de datos en la capa analytics
-- ============================================================
-- Objetivo:
-- Este script puebla las dimensiones y tablas de hechos del schema
-- analytics a partir de las tablas limpias del schema core.
--
-- Este archivo contiene operaciones DML:
-- - INSERT INTO ... SELECT ...
-- - Transformaciones ligeras para construir dimensiones y hechos
-- - Cálculo de métricas derivadas
--
-- Requisito previo:
-- Ejecutar antes:
-- 01_create_analytics_tables.sql
--
-- Orden de carga:
-- 1. dim_geography
-- 2. dim_customer
-- 3. dim_seller
-- 4. dim_product
-- 5. dim_order_status
-- 6. dim_date
-- 7. fact_orders
-- 8. fact_order_items
-- ============================================================


-- ============================================================
-- 01. Poblar dim_geography ampliada
-- ============================================================
-- Esta dimensión se construye con todos los zip codes presentes en:
-- 1. core.geolocations
-- 2. core.customers
-- 3. core.sellers
--
-- Cuando hay coordenadas en geolocations, se incorporan.
-- Cuando no hay coordenadas, latitude y longitude quedan como NULL.
-- ============================================================

INSERT INTO analytics.dim_geography (
    zip_code_prefix,
    city,
    state,
    latitude,
    longitude
)
WITH all_zip_codes AS (
    SELECT geolocation_zip_code_prefix::TEXT AS zip_code_prefix
    FROM core.geolocations
    WHERE geolocation_zip_code_prefix IS NOT NULL

    UNION

    SELECT customer_zip_code_prefix::TEXT AS zip_code_prefix
    FROM core.customers
    WHERE customer_zip_code_prefix IS NOT NULL

    UNION

    SELECT seller_zip_code_prefix::TEXT AS zip_code_prefix
    FROM core.sellers
    WHERE seller_zip_code_prefix IS NOT NULL
),

geo AS (
    SELECT
        geolocation_zip_code_prefix::TEXT AS zip_code_prefix,
        MIN(geolocation_city) AS city,
        MIN(geolocation_state) AS state,
        AVG(geolocation_lat)::DOUBLE PRECISION AS latitude,
        AVG(geolocation_lng)::DOUBLE PRECISION AS longitude
    FROM core.geolocations
    WHERE geolocation_zip_code_prefix IS NOT NULL
    GROUP BY geolocation_zip_code_prefix
),

customer_geo AS (
    SELECT DISTINCT ON (customer_zip_code_prefix)
        customer_zip_code_prefix::TEXT AS zip_code_prefix,
        customer_city AS city,
        customer_state AS state
    FROM core.customers
    WHERE customer_zip_code_prefix IS NOT NULL
    ORDER BY customer_zip_code_prefix
),

seller_geo AS (
    SELECT DISTINCT ON (seller_zip_code_prefix)
        seller_zip_code_prefix::TEXT AS zip_code_prefix,
        seller_city AS city,
        seller_state AS state
    FROM core.sellers
    WHERE seller_zip_code_prefix IS NOT NULL
    ORDER BY seller_zip_code_prefix
)

SELECT
    z.zip_code_prefix,
    COALESCE(g.city, c.city, s.city) AS city,
    COALESCE(g.state, c.state, s.state) AS state,
    g.latitude,
    g.longitude
FROM all_zip_codes AS z

LEFT JOIN geo AS g
    ON z.zip_code_prefix = g.zip_code_prefix

LEFT JOIN customer_geo AS c
    ON z.zip_code_prefix = c.zip_code_prefix

LEFT JOIN seller_geo AS s
    ON z.zip_code_prefix = s.zip_code_prefix;


-- ============================================================
-- 02. Poblar dim_customer
-- ============================================================

INSERT INTO analytics.dim_customer (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id::TEXT AS customer_id,
    customer_unique_id::TEXT AS customer_unique_id,
    customer_zip_code_prefix::TEXT AS customer_zip_code_prefix,
    customer_city::TEXT AS customer_city,
    customer_state::TEXT AS customer_state
FROM core.customers;


-- ============================================================
-- 03. Poblar dim_seller
-- ============================================================

INSERT INTO analytics.dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id::TEXT AS seller_id,
    seller_zip_code_prefix::TEXT AS seller_zip_code_prefix,
    seller_city::TEXT AS seller_city,
    seller_state::TEXT AS seller_state
FROM core.sellers;


-- ============================================================
-- 04. Poblar dim_product
-- ============================================================

INSERT INTO analytics.dim_product (
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_volume_cm3
)
SELECT
    product_id::TEXT AS product_id,
    product_category_name::TEXT AS product_category_name,
    product_weight_g::DOUBLE PRECISION AS product_weight_g,
    product_length_cm::DOUBLE PRECISION AS product_length_cm,
    product_height_cm::DOUBLE PRECISION AS product_height_cm,
    product_width_cm::DOUBLE PRECISION AS product_width_cm,
    (
        product_length_cm::DOUBLE PRECISION *
        product_height_cm::DOUBLE PRECISION *
        product_width_cm::DOUBLE PRECISION
    ) AS product_volume_cm3
FROM core.products;


-- ============================================================
-- 05. Poblar dim_order_status
-- ============================================================

INSERT INTO analytics.dim_order_status (
    order_status
)
SELECT DISTINCT
    order_status::TEXT AS order_status
FROM core.orders
WHERE order_status IS NOT NULL;


-- ============================================================
-- 06. Poblar dim_date
-- ============================================================

INSERT INTO analytics.dim_date (
    date_key,
    full_date,
    year,
    month,
    month_name,
    day,
    day_of_week,
    quarter
)
WITH all_dates AS (
    SELECT order_purchase_timestamp::DATE AS full_date
    FROM core.orders
    WHERE order_purchase_timestamp IS NOT NULL

    UNION

    SELECT order_approved_at::DATE AS full_date
    FROM core.orders
    WHERE order_approved_at IS NOT NULL

    UNION

    SELECT order_delivered_carrier_date::DATE AS full_date
    FROM core.orders
    WHERE order_delivered_carrier_date IS NOT NULL

    UNION

    SELECT order_delivered_customer_date::DATE AS full_date
    FROM core.orders
    WHERE order_delivered_customer_date IS NOT NULL

    UNION

    SELECT order_estimated_delivery_date::DATE AS full_date
    FROM core.orders
    WHERE order_estimated_delivery_date IS NOT NULL

    UNION

    SELECT shipping_limit_date::DATE AS full_date
    FROM core.order_items
    WHERE shipping_limit_date IS NOT NULL
)

SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::INTEGER AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date)::INTEGER AS year,
    EXTRACT(MONTH FROM full_date)::INTEGER AS month,
    TO_CHAR(full_date, 'Month') AS month_name,
    EXTRACT(DAY FROM full_date)::INTEGER AS day,
    TO_CHAR(full_date, 'Day') AS day_of_week,
    EXTRACT(QUARTER FROM full_date)::INTEGER AS quarter
FROM all_dates;


-- ============================================================
-- 07. Poblar fact_orders
-- ============================================================

INSERT INTO analytics.fact_orders (
    order_id,
    customer_id,
    order_status,

    purchase_date_key,
    approved_date_key,
    delivered_carrier_date_key,
    delivered_customer_date_key,
    estimated_delivery_date_key,

    approval_time_days,
    carrier_dispatch_time_days,
    delivery_time_days,
    total_delivery_time_days,
    delay_days,
    is_delayed,

    total_items_value,
    total_freight_value,
    number_of_items,
    number_of_products,
    number_of_sellers,

    total_payment_value,
    number_of_payment_operations,
    max_payment_installments,

    avg_review_score,
    number_of_reviews
)
WITH items_by_order AS (
    SELECT
        order_id::TEXT AS order_id,
        SUM(price)::DOUBLE PRECISION AS total_items_value,
        SUM(freight_value)::DOUBLE PRECISION AS total_freight_value,
        COUNT(*)::INTEGER AS number_of_items,
        COUNT(DISTINCT product_id)::INTEGER AS number_of_products,
        COUNT(DISTINCT seller_id)::INTEGER AS number_of_sellers
    FROM core.order_items
    GROUP BY order_id
),

payments_by_order AS (
    SELECT
        order_id::TEXT AS order_id,
        SUM(payment_value)::DOUBLE PRECISION AS total_payment_value,
        COUNT(*)::INTEGER AS number_of_payment_operations,
        MAX(payment_installments)::INTEGER AS max_payment_installments
    FROM core.order_payments
    GROUP BY order_id
),

reviews_by_order AS (
    SELECT
        order_id::TEXT AS order_id,
        AVG(review_score)::DOUBLE PRECISION AS avg_review_score,
        COUNT(review_id)::INTEGER AS number_of_reviews
    FROM core.order_reviews
    GROUP BY order_id
)

SELECT
    o.order_id::TEXT AS order_id,
    o.customer_id::TEXT AS customer_id,
    o.order_status::TEXT AS order_status,

    CASE 
        WHEN o.order_purchase_timestamp IS NOT NULL
        THEN TO_CHAR(o.order_purchase_timestamp::DATE, 'YYYYMMDD')::INTEGER
    END AS purchase_date_key,

    CASE 
        WHEN o.order_approved_at IS NOT NULL
        THEN TO_CHAR(o.order_approved_at::DATE, 'YYYYMMDD')::INTEGER
    END AS approved_date_key,

    CASE 
        WHEN o.order_delivered_carrier_date IS NOT NULL
        THEN TO_CHAR(o.order_delivered_carrier_date::DATE, 'YYYYMMDD')::INTEGER
    END AS delivered_carrier_date_key,

    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN TO_CHAR(o.order_delivered_customer_date::DATE, 'YYYYMMDD')::INTEGER
    END AS delivered_customer_date_key,

    CASE 
        WHEN o.order_estimated_delivery_date IS NOT NULL
        THEN TO_CHAR(o.order_estimated_delivery_date::DATE, 'YYYYMMDD')::INTEGER
    END AS estimated_delivery_date_key,

    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_approved_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 86400
    END AS approval_time_days,

    CASE
        WHEN o.order_approved_at IS NOT NULL
         AND o.order_delivered_carrier_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at)) / 86400
    END AS carrier_dispatch_time_days,

    CASE
        WHEN o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_customer_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date)) / 86400
    END AS delivery_time_days,

    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_delivered_customer_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400
    END AS total_delivery_time_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400
    END AS delay_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_delivered_customer_date > o.order_estimated_delivery_date
    END AS is_delayed,

    COALESCE(i.total_items_value, 0) AS total_items_value,
    COALESCE(i.total_freight_value, 0) AS total_freight_value,
    COALESCE(i.number_of_items, 0) AS number_of_items,
    COALESCE(i.number_of_products, 0) AS number_of_products,
    COALESCE(i.number_of_sellers, 0) AS number_of_sellers,

    COALESCE(p.total_payment_value, 0) AS total_payment_value,
    COALESCE(p.number_of_payment_operations, 0) AS number_of_payment_operations,
    p.max_payment_installments,

    r.avg_review_score,
    COALESCE(r.number_of_reviews, 0) AS number_of_reviews

FROM core.orders AS o

LEFT JOIN items_by_order AS i
    ON o.order_id::TEXT = i.order_id

LEFT JOIN payments_by_order AS p
    ON o.order_id::TEXT = p.order_id

LEFT JOIN reviews_by_order AS r
    ON o.order_id::TEXT = r.order_id;


-- ============================================================
-- 08. Poblar fact_order_items
-- ============================================================

INSERT INTO analytics.fact_order_items (
    order_id,
    order_item_id,
    customer_id,
    product_id,
    seller_id,
    shipping_date_key,
    shipping_limit_date,
    price,
    freight_value,
    line_total_value
)
SELECT
    oi.order_id::TEXT AS order_id,
    oi.order_item_id::INTEGER AS order_item_id,
    o.customer_id::TEXT AS customer_id,
    oi.product_id::TEXT AS product_id,
    oi.seller_id::TEXT AS seller_id,

    CASE 
        WHEN oi.shipping_limit_date IS NOT NULL
        THEN TO_CHAR(oi.shipping_limit_date::DATE, 'YYYYMMDD')::INTEGER
    END AS shipping_date_key,

    oi.shipping_limit_date AS shipping_limit_date,
    oi.price::DOUBLE PRECISION AS price,
    oi.freight_value::DOUBLE PRECISION AS freight_value,
    (oi.price + oi.freight_value)::DOUBLE PRECISION AS line_total_value

FROM core.order_items AS oi

LEFT JOIN core.orders AS o
    ON oi.order_id = o.order_id;