-- ============================================================
-- 06_vw_product_weight_volume_analysis.sql
-- Vistas de rendimiento logístico según peso y volumen del pedido
-- ============================================================
-- Objetivo:
-- Crear vistas reutilizables para Power BI que permitan analizar
-- si las características físicas del pedido se relacionan con el
-- rendimiento logístico.
--
-- Variables analizadas:
-- - Peso total estimado del pedido.
-- - Volumen total estimado del pedido.
-- - Coste medio de envío por rango de peso.
-- - Tiempo medio de entrega por rango de peso.
-- - Porcentaje de retraso por rango de peso.
-- - Porcentaje de retraso por rango de volumen.
--
-- Vistas creadas:
-- - analytics.vw_avg_weight_by_delivery_status
-- - analytics.vw_avg_volume_by_delivery_status
-- - analytics.vw_freight_cost_by_weight_bucket
-- - analytics.vw_delivery_time_by_weight_bucket
-- - analytics.vw_delay_by_weight_bucket
-- - analytics.vw_delay_by_volume_bucket
--
-- Tablas utilizadas:
-- - analytics.fact_orders
-- - analytics.fact_order_items
-- - analytics.dim_product
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - is_delayed = true indica que el pedido fue entregado con retraso.
-- - is_delayed = false indica que el pedido fue entregado en plazo.
-- - Se excluyen registros con is_delayed IS NULL porque no pueden
--   clasificarse de forma segura como retrasados o no retrasados.
-- - El peso total del pedido se calcula sumando el peso de los productos
--   incluidos en cada pedido.
-- - El volumen total del pedido se calcula sumando el volumen de los
--   productos incluidos en cada pedido.
-- - El volumen se calcula como:
--   product_length_cm * product_height_cm * product_width_cm.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Vista: peso medio de pedidos retrasados y no retrasados
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_avg_weight_by_delivery_status AS
WITH order_physical_features AS (
    SELECT
        o.order_id,
        o.is_delayed,

        SUM(p.product_weight_g) AS total_order_weight_g,

        SUM(
            p.product_length_cm
            * p.product_height_cm
            * p.product_width_cm
        ) AS total_order_volume_cm3

    FROM analytics.fact_orders AS o
    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id
    INNER JOIN analytics.dim_product AS p
        ON i.product_id = p.product_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL

    GROUP BY
        o.order_id,
        o.is_delayed
)

SELECT
    CASE
        WHEN is_delayed = true THEN 'Retrasado'
        WHEN is_delayed = false THEN 'No retrasado'
    END AS delivery_status,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(total_order_weight_g)::numeric,
        2
    ) AS avg_order_weight_g,

    ROUND(
        AVG(total_order_weight_g / 1000.0)::numeric,
        2
    ) AS avg_order_weight_kg

FROM order_physical_features

WHERE total_order_weight_g IS NOT NULL

GROUP BY is_delayed

ORDER BY is_delayed DESC;


-- ============================================================
-- 2. Vista: volumen medio de pedidos retrasados y no retrasados
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_avg_volume_by_delivery_status AS
WITH order_physical_features AS (
    SELECT
        o.order_id,
        o.is_delayed,

        SUM(p.product_weight_g) AS total_order_weight_g,

        SUM(
            p.product_length_cm
            * p.product_height_cm
            * p.product_width_cm
        ) AS total_order_volume_cm3

    FROM analytics.fact_orders AS o
    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id
    INNER JOIN analytics.dim_product AS p
        ON i.product_id = p.product_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL

    GROUP BY
        o.order_id,
        o.is_delayed
)

SELECT
    CASE
        WHEN is_delayed = true THEN 'Retrasado'
        WHEN is_delayed = false THEN 'No retrasado'
    END AS delivery_status,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(total_order_volume_cm3)::numeric,
        2
    ) AS avg_order_volume_cm3,

    ROUND(
        AVG(total_order_volume_cm3 / 1000.0)::numeric,
        2
    ) AS avg_order_volume_liters

FROM order_physical_features

WHERE total_order_volume_cm3 IS NOT NULL

GROUP BY is_delayed

ORDER BY is_delayed DESC;


-- ============================================================
-- 3. Vista: coste medio de envío por rango de peso
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_freight_cost_by_weight_bucket AS
WITH order_physical_features AS (
    SELECT
        o.order_id,
        o.is_delayed,
        o.total_delivery_time_days,
        o.total_freight_value,

        SUM(p.product_weight_g) AS total_order_weight_g,

        SUM(
            p.product_length_cm
            * p.product_height_cm
            * p.product_width_cm
        ) AS total_order_volume_cm3

    FROM analytics.fact_orders AS o
    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id
    INNER JOIN analytics.dim_product AS p
        ON i.product_id = p.product_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL

    GROUP BY
        o.order_id,
        o.is_delayed,
        o.total_delivery_time_days,
        o.total_freight_value
),

weight_buckets AS (
    SELECT
        order_id,
        total_freight_value,
        total_order_weight_g,

        CASE
            WHEN total_order_weight_g > 0
             AND total_order_weight_g <= 500 THEN '0-500 g'
            WHEN total_order_weight_g > 500
             AND total_order_weight_g <= 1000 THEN '500 g-1 kg'
            WHEN total_order_weight_g > 1000
             AND total_order_weight_g <= 5000 THEN '1-5 kg'
            WHEN total_order_weight_g > 5000
             AND total_order_weight_g <= 10000 THEN '5-10 kg'
            WHEN total_order_weight_g > 10000 THEN 'Más de 10 kg'
        END AS weight_bucket,

        CASE
            WHEN total_order_weight_g > 0
             AND total_order_weight_g <= 500 THEN 1
            WHEN total_order_weight_g > 500
             AND total_order_weight_g <= 1000 THEN 2
            WHEN total_order_weight_g > 1000
             AND total_order_weight_g <= 5000 THEN 3
            WHEN total_order_weight_g > 5000
             AND total_order_weight_g <= 10000 THEN 4
            WHEN total_order_weight_g > 10000 THEN 5
        END AS bucket_order

    FROM order_physical_features

    WHERE total_order_weight_g IS NOT NULL
)

SELECT
    weight_bucket,
    bucket_order,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(total_freight_value)::numeric,
        2
    ) AS avg_freight_value

FROM weight_buckets

WHERE weight_bucket IS NOT NULL
  AND total_freight_value IS NOT NULL

GROUP BY
    weight_bucket,
    bucket_order

ORDER BY bucket_order;


-- ============================================================
-- 4. Vista: tiempo medio de entrega por rango de peso
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delivery_time_by_weight_bucket AS
WITH order_physical_features AS (
    SELECT
        o.order_id,
        o.is_delayed,
        o.total_delivery_time_days,
        o.total_freight_value,

        SUM(p.product_weight_g) AS total_order_weight_g,

        SUM(
            p.product_length_cm
            * p.product_height_cm
            * p.product_width_cm
        ) AS total_order_volume_cm3

    FROM analytics.fact_orders AS o
    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id
    INNER JOIN analytics.dim_product AS p
        ON i.product_id = p.product_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL

    GROUP BY
        o.order_id,
        o.is_delayed,
        o.total_delivery_time_days,
        o.total_freight_value
),

weight_buckets AS (
    SELECT
        order_id,
        total_delivery_time_days,
        total_order_weight_g,

        CASE
            WHEN total_order_weight_g > 0
             AND total_order_weight_g <= 500 THEN '0-500 g'
            WHEN total_order_weight_g > 500
             AND total_order_weight_g <= 1000 THEN '500 g-1 kg'
            WHEN total_order_weight_g > 1000
             AND total_order_weight_g <= 5000 THEN '1-5 kg'
            WHEN total_order_weight_g > 5000
             AND total_order_weight_g <= 10000 THEN '5-10 kg'
            WHEN total_order_weight_g > 10000 THEN 'Más de 10 kg'
        END AS weight_bucket,

        CASE
            WHEN total_order_weight_g > 0
             AND total_order_weight_g <= 500 THEN 1
            WHEN total_order_weight_g > 500
             AND total_order_weight_g <= 1000 THEN 2
            WHEN total_order_weight_g > 1000
             AND total_order_weight_g <= 5000 THEN 3
            WHEN total_order_weight_g > 5000
             AND total_order_weight_g <= 10000 THEN 4
            WHEN total_order_weight_g > 10000 THEN 5
        END AS bucket_order

    FROM order_physical_features

    WHERE total_order_weight_g IS NOT NULL
)

SELECT
    weight_bucket,
    bucket_order,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(total_delivery_time_days)::numeric,
        2
    ) AS avg_total_delivery_time_days

FROM weight_buckets

WHERE weight_bucket IS NOT NULL
  AND total_delivery_time_days IS NOT NULL

GROUP BY
    weight_bucket,
    bucket_order

ORDER BY bucket_order;


-- ============================================================
-- 5. Vista: porcentaje de retraso por rango de peso
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_by_weight_bucket AS
WITH order_physical_features AS (
    SELECT
        o.order_id,
        o.is_delayed,

        SUM(p.product_weight_g) AS total_order_weight_g,

        SUM(
            p.product_length_cm
            * p.product_height_cm
            * p.product_width_cm
        ) AS total_order_volume_cm3

    FROM analytics.fact_orders AS o
    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id
    INNER JOIN analytics.dim_product AS p
        ON i.product_id = p.product_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL

    GROUP BY
        o.order_id,
        o.is_delayed
),

weight_buckets AS (
    SELECT
        order_id,
        is_delayed,
        total_order_weight_g,

        CASE
            WHEN total_order_weight_g > 0
             AND total_order_weight_g <= 500 THEN '0-500 g'
            WHEN total_order_weight_g > 500
             AND total_order_weight_g <= 1000 THEN '500 g-1 kg'
            WHEN total_order_weight_g > 1000
             AND total_order_weight_g <= 5000 THEN '1-5 kg'
            WHEN total_order_weight_g > 5000
             AND total_order_weight_g <= 10000 THEN '5-10 kg'
            WHEN total_order_weight_g > 10000 THEN 'Más de 10 kg'
        END AS weight_bucket,

        CASE
            WHEN total_order_weight_g > 0
             AND total_order_weight_g <= 500 THEN 1
            WHEN total_order_weight_g > 500
             AND total_order_weight_g <= 1000 THEN 2
            WHEN total_order_weight_g > 1000
             AND total_order_weight_g <= 5000 THEN 3
            WHEN total_order_weight_g > 5000
             AND total_order_weight_g <= 10000 THEN 4
            WHEN total_order_weight_g > 10000 THEN 5
        END AS bucket_order

    FROM order_physical_features

    WHERE total_order_weight_g IS NOT NULL
)

SELECT
    weight_bucket,
    bucket_order,

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE is_delayed = true
    ) AS delayed_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*),
            0
        ) * 100,
        2
    ) AS delayed_percentage_within_weight_bucket

FROM weight_buckets

WHERE weight_bucket IS NOT NULL

GROUP BY
    weight_bucket,
    bucket_order

ORDER BY bucket_order;


-- ============================================================
-- 6. Vista: porcentaje de retraso por rango de volumen
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_by_volume_bucket AS
WITH order_physical_features AS (
    SELECT
        o.order_id,
        o.is_delayed,

        SUM(p.product_weight_g) AS total_order_weight_g,

        SUM(
            p.product_length_cm
            * p.product_height_cm
            * p.product_width_cm
        ) AS total_order_volume_cm3

    FROM analytics.fact_orders AS o
    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id
    INNER JOIN analytics.dim_product AS p
        ON i.product_id = p.product_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL

    GROUP BY
        o.order_id,
        o.is_delayed
),

volume_buckets AS (
    SELECT
        order_id,
        is_delayed,
        total_order_volume_cm3,

        CASE
            WHEN total_order_volume_cm3 > 0
             AND total_order_volume_cm3 <= 1000 THEN '0-1 L'
            WHEN total_order_volume_cm3 > 1000
             AND total_order_volume_cm3 <= 5000 THEN '1-5 L'
            WHEN total_order_volume_cm3 > 5000
             AND total_order_volume_cm3 <= 10000 THEN '5-10 L'
            WHEN total_order_volume_cm3 > 10000
             AND total_order_volume_cm3 <= 50000 THEN '10-50 L'
            WHEN total_order_volume_cm3 > 50000 THEN 'Más de 50 L'
        END AS volume_bucket,

        CASE
            WHEN total_order_volume_cm3 > 0
             AND total_order_volume_cm3 <= 1000 THEN 1
            WHEN total_order_volume_cm3 > 1000
             AND total_order_volume_cm3 <= 5000 THEN 2
            WHEN total_order_volume_cm3 > 5000
             AND total_order_volume_cm3 <= 10000 THEN 3
            WHEN total_order_volume_cm3 > 10000
             AND total_order_volume_cm3 <= 50000 THEN 4
            WHEN total_order_volume_cm3 > 50000 THEN 5
        END AS bucket_order

    FROM order_physical_features

    WHERE total_order_volume_cm3 IS NOT NULL
)

SELECT
    volume_bucket,
    bucket_order,

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE is_delayed = true
    ) AS delayed_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*),
            0
        ) * 100,
        2
    ) AS delayed_percentage_within_volume_bucket

FROM volume_buckets

WHERE volume_bucket IS NOT NULL

GROUP BY
    volume_bucket,
    bucket_order

ORDER BY bucket_order;


-- ============================================================
-- 7. Comprobación de vistas creadas
-- ============================================================

SELECT *
FROM analytics.vw_avg_weight_by_delivery_status;

SELECT *
FROM analytics.vw_avg_volume_by_delivery_status;

SELECT *
FROM analytics.vw_freight_cost_by_weight_bucket;

SELECT *
FROM analytics.vw_delivery_time_by_weight_bucket;

SELECT *
FROM analytics.vw_delay_by_weight_bucket;

SELECT *
FROM analytics.vw_delay_by_volume_bucket;