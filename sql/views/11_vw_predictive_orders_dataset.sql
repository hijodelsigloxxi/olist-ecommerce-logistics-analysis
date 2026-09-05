-- ============================================================
-- 11_vw_predictive_orders_dataset.sql
-- Vista para la construcción de la capa predictiva
-- ============================================================
-- Objetivo:
-- Crear una vista analítica con una fila por pedido entregado,
-- preparada para ser exportada a Python y utilizada en modelos
-- de clasificación binaria.
--
-- Variable objetivo:
-- is_delayed
--   false = pedido entregado en plazo
--   true  = pedido entregado con retraso
--
-- Criterio metodológico:
-- Se excluyen variables conocidas después de la entrega, como
-- delay_days, total_delivery_time_days y avg_review_score, para
-- evitar fuga de información en el modelo predictivo.
--
-- Vista creada:
-- analytics.vw_predictive_orders_dataset
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_predictive_orders_dataset AS
WITH order_seller_state AS (
    SELECT
        o.order_id,
        c.customer_state,
        COUNT(DISTINCT s.seller_state) AS number_of_seller_states,
        MIN(s.seller_state) AS main_seller_state,

        CASE
            WHEN COUNT(DISTINCT s.seller_state) = 1
             AND MIN(s.seller_state) = c.customer_state
                THEN 'Mismo estado'
            ELSE 'Distinto estado'
        END AS same_state_order

    FROM analytics.fact_orders AS o

    INNER JOIN analytics.dim_customer AS c
        ON o.customer_id = c.customer_id

    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id

    INNER JOIN analytics.dim_seller AS s
        ON i.seller_id = s.seller_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL

    GROUP BY
        o.order_id,
        c.customer_state
),

order_product_features AS (
    SELECT
        i.order_id,

        ROUND(AVG(p.product_weight_g)::numeric, 2) AS avg_product_weight_g,

        ROUND(AVG(p.product_volume_cm3)::numeric, 2) AS avg_product_volume_cm3,

        ROUND(SUM(p.product_weight_g)::numeric, 2) AS total_product_weight_g,

        ROUND(SUM(p.product_volume_cm3)::numeric, 2) AS total_product_volume_cm3,

        COUNT(DISTINCT p.product_category_name) AS number_of_product_categories,

        COALESCE(
            MODE() WITHIN GROUP (
                ORDER BY p.product_category_name
            ),
            'Sin categoría'
        ) AS main_product_category

    FROM analytics.fact_order_items AS i

    INNER JOIN analytics.dim_product AS p
        ON i.product_id = p.product_id

    GROUP BY
        i.order_id
),

order_purchase_date AS (
    SELECT
        o.order_id,
        EXTRACT(YEAR FROM co.order_purchase_timestamp)::integer AS purchase_year,
        EXTRACT(MONTH FROM co.order_purchase_timestamp)::integer AS purchase_month,
        EXTRACT(QUARTER FROM co.order_purchase_timestamp)::integer AS purchase_quarter,
        EXTRACT(DOW FROM co.order_purchase_timestamp)::integer AS purchase_day_of_week

    FROM analytics.fact_orders AS o

    INNER JOIN core.orders AS co
        ON o.order_id = co.order_id

    WHERE co.order_purchase_timestamp IS NOT NULL
)

SELECT
    -- Identificador
    o.order_id,

    -- Variable objetivo
    o.is_delayed,

    -- Estado del pedido
    o.order_status,

    -- Variables temporales disponibles antes o durante el proceso logístico
    o.approval_time_days,

    -- Variables de complejidad del pedido
    o.number_of_items,
    o.number_of_products,
    o.number_of_sellers,

    -- Variables económicas conocidas en el momento de la compra
    o.total_items_value,
    o.total_freight_value,
    o.total_payment_value,

    -- Variables de producto agregadas a nivel pedido
    opf.avg_product_weight_g,
    opf.avg_product_volume_cm3,
    opf.total_product_weight_g,
    opf.total_product_volume_cm3,
    opf.number_of_product_categories,
    opf.main_product_category,

    -- Variables territoriales
    oss.customer_state,
    oss.main_seller_state,
    oss.number_of_seller_states,
    oss.same_state_order,

    -- Variables temporales de compra
    opd.purchase_year,
    opd.purchase_month,
    opd.purchase_quarter,
    opd.purchase_day_of_week

FROM analytics.fact_orders AS o

LEFT JOIN order_seller_state AS oss
    ON o.order_id = oss.order_id

LEFT JOIN order_product_features AS opf
    ON o.order_id = opf.order_id

LEFT JOIN order_purchase_date AS opd
    ON o.order_id = opd.order_id

WHERE o.order_status = 'delivered'
  AND o.is_delayed IS NOT NULL;
  
-- ============================================================
-- Comprobación de la vista predictiva
-- ============================================================

SELECT *
FROM analytics.vw_predictive_orders_dataset
LIMIT 100;


-- ============================================================
-- Recuento total de registros y distribución de la variable objetivo
-- ============================================================

SELECT
    COUNT(*) AS total_pedidos,
    COUNT(*) FILTER (WHERE is_delayed = true) AS pedidos_retrasados,
    COUNT(*) FILTER (WHERE is_delayed = false) AS pedidos_no_retrasados,
    ROUND(
        COUNT(*) FILTER (WHERE is_delayed = true)::numeric
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS porcentaje_retrasos
FROM analytics.vw_predictive_orders_dataset;


-- ============================================================
-- Comprobación de nulos en variables principales
-- ============================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE approval_time_days IS NULL) AS null_approval_time_days,
    COUNT(*) FILTER (WHERE number_of_items IS NULL) AS null_number_of_items,
    COUNT(*) FILTER (WHERE number_of_products IS NULL) AS null_number_of_products,
    COUNT(*) FILTER (WHERE number_of_sellers IS NULL) AS null_number_of_sellers,

    COUNT(*) FILTER (WHERE total_items_value IS NULL) AS null_total_items_value,
    COUNT(*) FILTER (WHERE total_freight_value IS NULL) AS null_total_freight_value,
    COUNT(*) FILTER (WHERE total_payment_value IS NULL) AS null_total_payment_value,

    COUNT(*) FILTER (WHERE customer_state IS NULL) AS null_customer_state,
    COUNT(*) FILTER (WHERE main_seller_state IS NULL) AS null_main_seller_state,
    COUNT(*) FILTER (WHERE same_state_order IS NULL) AS null_same_state_order,

    COUNT(*) FILTER (WHERE purchase_year IS NULL) AS null_purchase_year,
    COUNT(*) FILTER (WHERE purchase_month IS NULL) AS null_purchase_month

FROM analytics.vw_predictive_orders_dataset;