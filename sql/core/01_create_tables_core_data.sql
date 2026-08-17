-- ============================================================
-- 01_create_tables_core_data.sql
-- Creación y validación inicial del modelo relacional core
-- ============================================================
-- Objetivo:
-- Este script crea el schema core y las tablas relacionales que
-- conservan la estructura transaccional original del dataset Olist.
--
-- Además, al final incluye consultas de validación para comprobar:
-- - Recuento de registros por tabla.
-- - Unicidad de claves primarias.
-- - Duplicados en claves compuestas.
-- - Correspondencia entre claves foráneas y tablas de referencia.
-- - Nulos en campos obligatorios.
--
-- Nota:
-- Las consultas de validación deben ejecutarse después de haber cargado
-- los datos en las tablas core.
-- ============================================================


-- ============================================================
-- 01. Crear schema core
-- ============================================================

CREATE SCHEMA IF NOT EXISTS core;


-- ============================================================
-- 02. Crear tabla geolocations
-- ============================================================

CREATE TABLE core.geolocations (
    geolocation_zip_code_prefix TEXT PRIMARY KEY,
    geolocation_lat DOUBLE PRECISION,
    geolocation_lng DOUBLE PRECISION,
    geolocation_city TEXT,
    geolocation_state TEXT
);


-- ============================================================
-- 03. Crear tabla customers
-- ============================================================

CREATE TABLE core.customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix TEXT NOT NULL,
    customer_city TEXT NOT NULL,
    customer_state TEXT NOT NULL
);


-- ============================================================
-- 04. Crear tabla sellers
-- ============================================================

CREATE TABLE core.sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT NOT NULL,
    seller_city TEXT NOT NULL,
    seller_state TEXT NOT NULL
);


-- ============================================================
-- 05. Crear tabla products
-- ============================================================

CREATE TABLE core.products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght DOUBLE PRECISION,
    product_description_lenght DOUBLE PRECISION,
    product_photos_qty DOUBLE PRECISION,
    product_weight_g DOUBLE PRECISION,
    product_length_cm DOUBLE PRECISION,
    product_height_cm DOUBLE PRECISION,
    product_width_cm DOUBLE PRECISION
);


-- ============================================================
-- 06. Crear tabla orders
-- ============================================================

CREATE TABLE core.orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES core.customers(customer_id)
);


-- ============================================================
-- 07. Crear tabla order_items
-- ============================================================

CREATE TABLE core.order_items (
    order_id TEXT NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id TEXT NOT NULL,
    seller_id TEXT NOT NULL,
    shipping_limit_date TIMESTAMP NOT NULL,
    price DOUBLE PRECISION NOT NULL,
    freight_value DOUBLE PRECISION NOT NULL,

    CONSTRAINT pk_order_items
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES core.orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES core.products(product_id),

    CONSTRAINT fk_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES core.sellers(seller_id)
);


-- ============================================================
-- 08. Crear tabla order_payments
-- ============================================================

CREATE TABLE core.order_payments (
    order_id TEXT NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type TEXT NOT NULL,
    payment_installments INTEGER NOT NULL,
    payment_value DOUBLE PRECISION NOT NULL,

    CONSTRAINT pk_order_payments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_order_payments_order
        FOREIGN KEY (order_id)
        REFERENCES core.orders(order_id)
);


-- ============================================================
-- 09. Crear tabla order_reviews
-- ============================================================

CREATE TABLE core.order_reviews (
    review_row_id BIGSERIAL PRIMARY KEY,
    review_id TEXT NOT NULL,
    order_id TEXT NOT NULL,
    review_score INTEGER NOT NULL,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP NOT NULL,
    review_answer_timestamp TIMESTAMP NOT NULL,

    CONSTRAINT fk_order_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES core.orders(order_id)
);


-- ============================================================
-- VALIDACIONES DEL MODELO CORE
-- ============================================================
-- Ejecutar estas consultas después de importar los datos.
-- ============================================================


-- ============================================================
-- 10. Recuento general de registros por tabla
-- ============================================================

SELECT 'geolocations' AS table_name, COUNT(*) AS row_count FROM core.geolocations
UNION ALL
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM core.customers
UNION ALL
SELECT 'sellers' AS table_name, COUNT(*) AS row_count FROM core.sellers
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM core.products
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM core.orders
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM core.order_items
UNION ALL
SELECT 'order_payments' AS table_name, COUNT(*) AS row_count FROM core.order_payments
UNION ALL
SELECT 'order_reviews' AS table_name, COUNT(*) AS row_count FROM core.order_reviews
ORDER BY table_name;


-- ============================================================
-- 11. Validar clave primaria de geolocations
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS distinct_zip_codes
FROM core.geolocations;

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS n
FROM core.geolocations
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1;


-- ============================================================
-- 12. Validar clave primaria de customers
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM core.customers;

SELECT
    customer_id,
    COUNT(*) AS n
FROM core.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 13. Validar clave primaria de sellers
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS distinct_sellers
FROM core.sellers;

SELECT
    seller_id,
    COUNT(*) AS n
FROM core.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 14. Validar clave primaria de products
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS distinct_products
FROM core.products;

SELECT
    product_id,
    COUNT(*) AS n
FROM core.products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 15. Validar clave primaria de orders
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM core.orders;

SELECT
    order_id,
    COUNT(*) AS n
FROM core.orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 16. Validar clave primaria compuesta de order_items
-- ============================================================
-- La granularidad de order_items es una fila por combinación:
-- order_id + order_item_id.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id || '-' || order_item_id) AS distinct_order_item_rows
FROM core.order_items;

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS n
FROM core.order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 17. Validar clave primaria compuesta de order_payments
-- ============================================================
-- La granularidad de order_payments es una fila por combinación:
-- order_id + payment_sequential.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id || '-' || payment_sequential) AS distinct_payment_rows
FROM core.order_payments;

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS n
FROM core.order_payments
GROUP BY
    order_id,
    payment_sequential
HAVING COUNT(*) > 1;


-- ============================================================
-- 18. Validar clave técnica de order_reviews
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_row_id) AS distinct_review_rows
FROM core.order_reviews;

SELECT
    review_row_id,
    COUNT(*) AS n
FROM core.order_reviews
GROUP BY review_row_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 19. Revisar posible duplicidad original en reviews
-- ============================================================
-- review_row_id es la clave técnica creada por nosotros.
-- Esta consulta permite comprobar si la combinación original
-- review_id + order_id aparece más de una vez.
-- ============================================================

SELECT
    review_id,
    order_id,
    COUNT(*) AS n
FROM core.order_reviews
GROUP BY
    review_id,
    order_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 20. Validar relación orders -> customers
-- ============================================================

SELECT
    o.customer_id
FROM core.orders AS o
LEFT JOIN core.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ============================================================
-- 21. Validar relación order_items -> orders
-- ============================================================

SELECT
    i.order_id
FROM core.order_items AS i
LEFT JOIN core.orders AS o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 22. Validar relación order_items -> products
-- ============================================================

SELECT
    i.product_id
FROM core.order_items AS i
LEFT JOIN core.products AS p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ============================================================
-- 23. Validar relación order_items -> sellers
-- ============================================================

SELECT
    i.seller_id
FROM core.order_items AS i
LEFT JOIN core.sellers AS s
    ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- ============================================================
-- 24. Validar relación order_payments -> orders
-- ============================================================

SELECT
    p.order_id
FROM core.order_payments AS p
LEFT JOIN core.orders AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 25. Validar relación order_reviews -> orders
-- ============================================================

SELECT
    r.order_id
FROM core.order_reviews AS r
LEFT JOIN core.orders AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 26. Revisar nulos en campos obligatorios de orders
-- ============================================================

SELECT
    COUNT(*) AS rows_with_null_required_fields
FROM core.orders
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR order_status IS NULL
   OR order_purchase_timestamp IS NULL
   OR order_estimated_delivery_date IS NULL;


-- ============================================================
-- 27. Revisar nulos en campos obligatorios de order_items
-- ============================================================

SELECT
    COUNT(*) AS rows_with_null_required_fields
FROM core.order_items
WHERE order_id IS NULL
   OR order_item_id IS NULL
   OR product_id IS NULL
   OR seller_id IS NULL
   OR shipping_limit_date IS NULL
   OR price IS NULL
   OR freight_value IS NULL;


-- ============================================================
-- 28. Revisar nulos en campos obligatorios de order_payments
-- ============================================================

SELECT
    COUNT(*) AS rows_with_null_required_fields
FROM core.order_payments
WHERE order_id IS NULL
   OR payment_sequential IS NULL
   OR payment_type IS NULL
   OR payment_installments IS NULL
   OR payment_value IS NULL;


-- ============================================================
-- 29. Revisar nulos en campos obligatorios de order_reviews
-- ============================================================

SELECT
    COUNT(*) AS rows_with_null_required_fields
FROM core.order_reviews
WHERE review_row_id IS NULL
   OR review_id IS NULL
   OR order_id IS NULL
   OR review_score IS NULL
   OR review_creation_date IS NULL
   OR review_answer_timestamp IS NULL;
