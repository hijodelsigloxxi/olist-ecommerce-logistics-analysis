-- ============================================================
-- 04_vw_order_value_performance.sql
-- Vistas de rendimiento logístico según valor económico del pedido
-- ============================================================
-- Objetivo:
-- Crear vistas reutilizables para Power BI que permitan analizar
-- si el valor económico del pedido se relaciona con la probabilidad
-- de retraso logístico.
--
-- Variables analizadas:
-- - total_items_value
-- - total_payment_value
-- - total_freight_value
--
-- Vistas creadas:
-- - analytics.vw_delay_by_items_value_bucket
-- - analytics.vw_delay_by_payment_value_bucket
-- - analytics.vw_delay_by_freight_value_bucket
--
-- Tabla principal:
-- - analytics.fact_orders
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - Se excluyen registros con is_delayed IS NULL porque no pueden
--   clasificarse de forma segura como retrasados o no retrasados.
-- - porcentaje_sobre_total_retrasados indica qué proporción de todos
--   los pedidos retrasados pertenece a ese tramo económico.
-- - porcentaje_retraso_dentro_tramo indica qué proporción de los pedidos
--   del tramo económico se retrasó.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Vista: retrasos según valor total de productos
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_by_items_value_bucket AS
WITH value_base AS (
    SELECT
        order_id,
        is_delayed,

        CASE
            WHEN total_items_value > 0
             AND total_items_value <= 50 THEN '0-50'
            WHEN total_items_value > 50
             AND total_items_value <= 100 THEN '50-100'
            WHEN total_items_value > 100
             AND total_items_value <= 250 THEN '100-250'
            WHEN total_items_value > 250
             AND total_items_value <= 500 THEN '250-500'
            WHEN total_items_value > 500 THEN 'Más de 500'
        END AS value_bucket,

        CASE
            WHEN total_items_value > 0
             AND total_items_value <= 50 THEN 1
            WHEN total_items_value > 50
             AND total_items_value <= 100 THEN 2
            WHEN total_items_value > 100
             AND total_items_value <= 250 THEN 3
            WHEN total_items_value > 250
             AND total_items_value <= 500 THEN 4
            WHEN total_items_value > 500 THEN 5
        END AS bucket_order

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND is_delayed IS NOT NULL
      AND total_items_value IS NOT NULL
),

value_distribution AS (
    SELECT
        value_bucket,
        bucket_order,

        COUNT(*) AS total_pedidos,

        COUNT(*) FILTER (
            WHERE is_delayed = true
        ) AS pedidos_retrasados

    FROM value_base

    WHERE value_bucket IS NOT NULL

    GROUP BY
        value_bucket,
        bucket_order
)

SELECT
    value_bucket,
    bucket_order,
    total_pedidos,
    pedidos_retrasados,

    ROUND(
        pedidos_retrasados::numeric
        / NULLIF(
            SUM(pedidos_retrasados) OVER (),
            0
        ) * 100,
        2
    ) AS porcentaje_sobre_total_retrasados,

    ROUND(
        pedidos_retrasados::numeric
        / NULLIF(
            total_pedidos,
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_tramo

FROM value_distribution

ORDER BY bucket_order;


-- ============================================================
-- 2. Vista: retrasos según valor total pagado
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_by_payment_value_bucket AS
WITH payment_base AS (
    SELECT
        order_id,
        is_delayed,

        CASE
            WHEN total_payment_value > 0
             AND total_payment_value <= 50 THEN '0-50'
            WHEN total_payment_value > 50
             AND total_payment_value <= 100 THEN '50-100'
            WHEN total_payment_value > 100
             AND total_payment_value <= 250 THEN '100-250'
            WHEN total_payment_value > 250
             AND total_payment_value <= 500 THEN '250-500'
            WHEN total_payment_value > 500 THEN 'Más de 500'
        END AS value_bucket,

        CASE
            WHEN total_payment_value > 0
             AND total_payment_value <= 50 THEN 1
            WHEN total_payment_value > 50
             AND total_payment_value <= 100 THEN 2
            WHEN total_payment_value > 100
             AND total_payment_value <= 250 THEN 3
            WHEN total_payment_value > 250
             AND total_payment_value <= 500 THEN 4
            WHEN total_payment_value > 500 THEN 5
        END AS bucket_order

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND is_delayed IS NOT NULL
      AND total_payment_value IS NOT NULL
),

payment_distribution AS (
    SELECT
        value_bucket,
        bucket_order,

        COUNT(*) AS total_pedidos,

        COUNT(*) FILTER (
            WHERE is_delayed = true
        ) AS pedidos_retrasados

    FROM payment_base

    WHERE value_bucket IS NOT NULL

    GROUP BY
        value_bucket,
        bucket_order
)

SELECT
    value_bucket,
    bucket_order,
    total_pedidos,
    pedidos_retrasados,

    ROUND(
        pedidos_retrasados::numeric
        / NULLIF(
            SUM(pedidos_retrasados) OVER (),
            0
        ) * 100,
        2
    ) AS porcentaje_sobre_total_retrasados,

    ROUND(
        pedidos_retrasados::numeric
        / NULLIF(
            total_pedidos,
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_tramo

FROM payment_distribution

ORDER BY bucket_order;


-- ============================================================
-- 3. Vista: retrasos según coste total de envío
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_by_freight_value_bucket AS
WITH freight_base AS (
    SELECT
        order_id,
        is_delayed,

        CASE
            WHEN total_freight_value > 0
             AND total_freight_value <= 10 THEN '0-10'
            WHEN total_freight_value > 10
             AND total_freight_value <= 20 THEN '10-20'
            WHEN total_freight_value > 20
             AND total_freight_value <= 40 THEN '20-40'
            WHEN total_freight_value > 40
             AND total_freight_value <= 80 THEN '40-80'
            WHEN total_freight_value > 80 THEN 'Más de 80'
        END AS freight_bucket,

        CASE
            WHEN total_freight_value > 0
             AND total_freight_value <= 10 THEN 1
            WHEN total_freight_value > 10
             AND total_freight_value <= 20 THEN 2
            WHEN total_freight_value > 20
             AND total_freight_value <= 40 THEN 3
            WHEN total_freight_value > 40
             AND total_freight_value <= 80 THEN 4
            WHEN total_freight_value > 80 THEN 5
        END AS bucket_order

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND is_delayed IS NOT NULL
      AND total_freight_value IS NOT NULL
),

freight_distribution AS (
    SELECT
        freight_bucket,
        bucket_order,

        COUNT(*) AS total_pedidos,

        COUNT(*) FILTER (
            WHERE is_delayed = true
        ) AS pedidos_retrasados

    FROM freight_base

    WHERE freight_bucket IS NOT NULL

    GROUP BY
        freight_bucket,
        bucket_order
)

SELECT
    freight_bucket,
    bucket_order,
    total_pedidos,
    pedidos_retrasados,

    ROUND(
        pedidos_retrasados::numeric
        / NULLIF(
            SUM(pedidos_retrasados) OVER (),
            0
        ) * 100,
        2
    ) AS porcentaje_sobre_total_retrasados,

    ROUND(
        pedidos_retrasados::numeric
        / NULLIF(
            total_pedidos,
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_tramo

FROM freight_distribution

ORDER BY bucket_order;


-- ============================================================
-- 4. Comprobación de vistas creadas
-- ============================================================

SELECT *
FROM analytics.vw_delay_by_items_value_bucket;

SELECT *
FROM analytics.vw_delay_by_payment_value_bucket;

SELECT *
FROM analytics.vw_delay_by_freight_value_bucket;