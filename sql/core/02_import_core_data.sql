-- ============================================================
-- 02_import_core_data.sql
-- Importación de datos en el esquema core
-- Proyecto: Olist E-commerce Logistics Analysis
-- ============================================================
--
-- Este script documenta el orden lógico de importación de las tablas
-- del modelo relacional core.
--
-- IMPORTANTE:
-- Este archivo está pensado para ejecutarse desde psql, no desde pgAdmin,
-- porque utiliza \copy, que es un comando del cliente psql.
--
-- Orden de importación:
-- 1. geolocations
-- 2. customers
-- 3. sellers
-- 4. products
-- 5. orders
-- 6. order_items
-- 7. order_payments
-- 8. order_reviews
--
-- La tabla core.geolocations debe cargarse desde el archivo procesado,
-- no desde el CSV original, porque la tabla original de geolocalización
-- contiene múltiples registros por prefijo postal.
-- ============================================================


-- 1. Importar geolocations agregada por prefijo postal

\copy core.geolocations (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
FROM 'data/processed/geolocations.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- 2. Importar customers

\copy core.customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
FROM 'data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_customers_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- 3. Importar sellers

\copy core.sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
FROM 'data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_sellers_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- 4. Importar products

\copy core.products (
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
FROM 'data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_products_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- 5. Importar orders

\copy core.orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
FROM 'data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_orders_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- 6. Importar order_items

\copy core.order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
FROM 'data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_order_items_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- 7. Importar order_payments

\copy core.order_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
FROM 'data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_order_payments_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- 8. Importar order_reviews

\copy core.order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
FROM 'data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_order_reviews_dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- ============================================================
-- Validación rápida de conteos
-- ============================================================

SELECT 'geolocations' AS table_name, COUNT(*) AS total_rows FROM core.geolocations
UNION ALL
SELECT 'customers', COUNT(*) FROM core.customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM core.sellers
UNION ALL
SELECT 'products', COUNT(*) FROM core.products
UNION ALL
SELECT 'orders', COUNT(*) FROM core.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM core.order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM core.order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM core.order_reviews;