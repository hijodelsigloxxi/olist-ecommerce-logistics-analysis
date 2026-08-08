-- ============================================================
-- 01_create_analytics_tables.sql
-- Creación de tablas de la capa analytics
-- ============================================================
-- Objetivo:
-- Este script crea el schema analytics y las tablas dimensionales
-- y de hechos utilizadas para el análisis logístico del marketplace.
--
-- Este archivo contiene únicamente operaciones DDL:
-- - CREATE SCHEMA
-- - DROP TABLE
-- - CREATE TABLE
-- - Definición de claves primarias
-- - Definición de claves foráneas
--
-- No contiene inserciones de datos.
-- Las inserciones se realizan en:
-- 02_import_analytics_tables.sql
-- ============================================================


-- ============================================================
-- 01. Crear schema analytics
-- ============================================================

CREATE SCHEMA IF NOT EXISTS analytics;


-- ============================================================
-- 02. Eliminar tablas si ya existen
-- ============================================================
-- Se eliminan primero las tablas de hechos y después las dimensiones,
-- porque las tablas de hechos dependen de las dimensiones mediante
-- claves foráneas.
-- ============================================================

DROP TABLE IF EXISTS analytics.fact_order_items CASCADE;
DROP TABLE IF EXISTS analytics.fact_orders CASCADE;

DROP TABLE IF EXISTS analytics.dim_customer CASCADE;
DROP TABLE IF EXISTS analytics.dim_seller CASCADE;
DROP TABLE IF EXISTS analytics.dim_product CASCADE;
DROP TABLE IF EXISTS analytics.dim_order_status CASCADE;
DROP TABLE IF EXISTS analytics.dim_date CASCADE;
DROP TABLE IF EXISTS analytics.dim_geography CASCADE;


-- ============================================================
-- 03. Crear tabla dim_geography
-- ============================================================

CREATE TABLE analytics.dim_geography (
    zip_code_prefix TEXT PRIMARY KEY,
    city TEXT,
    state TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
);


-- ============================================================
-- 04. Crear tabla dim_customer
-- ============================================================

CREATE TABLE analytics.dim_customer (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix TEXT NOT NULL,
    customer_city TEXT NOT NULL,
    customer_state TEXT NOT NULL,

    CONSTRAINT fk_dim_customer_geography
        FOREIGN KEY (customer_zip_code_prefix)
        REFERENCES analytics.dim_geography(zip_code_prefix)
);


-- ============================================================
-- 05. Crear tabla dim_seller
-- ============================================================

CREATE TABLE analytics.dim_seller (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT NOT NULL,
    seller_city TEXT NOT NULL,
    seller_state TEXT NOT NULL,

    CONSTRAINT fk_dim_seller_geography
        FOREIGN KEY (seller_zip_code_prefix)
        REFERENCES analytics.dim_geography(zip_code_prefix)
);


-- ============================================================
-- 06. Crear tabla dim_product
-- ============================================================

CREATE TABLE analytics.dim_product (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_weight_g DOUBLE PRECISION,
    product_length_cm DOUBLE PRECISION,
    product_height_cm DOUBLE PRECISION,
    product_width_cm DOUBLE PRECISION,
    product_volume_cm3 DOUBLE PRECISION
);


-- ============================================================
-- 07. Crear tabla dim_order_status
-- ============================================================

CREATE TABLE analytics.dim_order_status (
    order_status TEXT PRIMARY KEY
);


-- ============================================================
-- 08. Crear tabla dim_date
-- ============================================================

CREATE TABLE analytics.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    day INTEGER NOT NULL,
    day_of_week TEXT NOT NULL,
    quarter INTEGER NOT NULL
);


-- ============================================================
-- 09. Crear tabla fact_orders
-- ============================================================

CREATE TABLE analytics.fact_orders (
    order_id TEXT PRIMARY KEY,

    customer_id TEXT NOT NULL,
    order_status TEXT,

    purchase_date_key INTEGER,
    approved_date_key INTEGER,
    delivered_carrier_date_key INTEGER,
    delivered_customer_date_key INTEGER,
    estimated_delivery_date_key INTEGER,

    approval_time_days DOUBLE PRECISION,
    carrier_dispatch_time_days DOUBLE PRECISION,
    delivery_time_days DOUBLE PRECISION,
    total_delivery_time_days DOUBLE PRECISION,
    delay_days DOUBLE PRECISION,
    is_delayed BOOLEAN,

    total_items_value DOUBLE PRECISION,
    total_freight_value DOUBLE PRECISION,
    number_of_items INTEGER,
    number_of_products INTEGER,
    number_of_sellers INTEGER,

    total_payment_value DOUBLE PRECISION,
    number_of_payment_operations INTEGER,
    max_payment_installments INTEGER,

    avg_review_score DOUBLE PRECISION,
    number_of_reviews INTEGER,

    CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES analytics.dim_customer(customer_id),

    CONSTRAINT fk_fact_orders_status
        FOREIGN KEY (order_status)
        REFERENCES analytics.dim_order_status(order_status),

    CONSTRAINT fk_fact_orders_purchase_date
        FOREIGN KEY (purchase_date_key)
        REFERENCES analytics.dim_date(date_key),

    CONSTRAINT fk_fact_orders_approved_date
        FOREIGN KEY (approved_date_key)
        REFERENCES analytics.dim_date(date_key),

    CONSTRAINT fk_fact_orders_delivered_carrier_date
        FOREIGN KEY (delivered_carrier_date_key)
        REFERENCES analytics.dim_date(date_key),

    CONSTRAINT fk_fact_orders_delivered_customer_date
        FOREIGN KEY (delivered_customer_date_key)
        REFERENCES analytics.dim_date(date_key),

    CONSTRAINT fk_fact_orders_estimated_delivery_date
        FOREIGN KEY (estimated_delivery_date_key)
        REFERENCES analytics.dim_date(date_key)
);


-- ============================================================
-- 10. Crear tabla fact_order_items
-- ============================================================

CREATE TABLE analytics.fact_order_items (
    order_id TEXT NOT NULL,
    order_item_id INTEGER NOT NULL,

    customer_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    seller_id TEXT NOT NULL,

    shipping_date_key INTEGER,
    shipping_limit_date TIMESTAMP,

    price DOUBLE PRECISION NOT NULL,
    freight_value DOUBLE PRECISION NOT NULL,
    line_total_value DOUBLE PRECISION NOT NULL,

    CONSTRAINT pk_fact_order_items
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_fact_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.fact_orders(order_id),

    CONSTRAINT fk_fact_order_items_customer
        FOREIGN KEY (customer_id)
        REFERENCES analytics.dim_customer(customer_id),

    CONSTRAINT fk_fact_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES analytics.dim_product(product_id),

    CONSTRAINT fk_fact_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES analytics.dim_seller(seller_id),

    CONSTRAINT fk_fact_order_items_shipping_date
        FOREIGN KEY (shipping_date_key)
        REFERENCES analytics.dim_date(date_key)
);