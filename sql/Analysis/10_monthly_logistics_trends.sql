-- ============================================================
-- 09_monthly_logistics_trends.sql
-- Evolución mensual del rendimiento logístico
-- ============================================================
-- Objetivo:
-- Este script analiza la evolución mensual de los principales
-- indicadores logísticos del marketplace.
--
-- Indicadores calculados:
-- - Pedidos por mes.
-- - Pedidos entregados por mes.
-- - Tasa mensual de retrasos.
-- - Tiempo medio mensual de entrega.
-- - Días medios de retraso por mes.
-- - Coste medio mensual de envío.
-- - Review score medio mensual.
--
-- Tablas utilizadas:
-- - analytics.fact_orders
-- - core.orders
--
-- Notas:
-- - El mes se calcula a partir de order_purchase_timestamp.
-- - Los indicadores logísticos se calculan sobre pedidos entregados.
-- - is_delayed = true indica que el pedido fue entregado con retraso.
-- - is_delayed = false indica que el pedido fue entregado dentro del plazo.
-- - Se excluyen registros con is_delayed IS NULL para los cálculos
--   relacionados con retrasos.
-- - Se utiliza COUNT(DISTINCT order_id) para evitar duplicidades.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Evolución mensual de pedidos e indicadores logísticos
-- ============================================================
-- Esta consulta resume, por mes de compra, el volumen de pedidos
-- y los principales indicadores de rendimiento logístico.
--
-- Interpretación:
-- - total_pedidos:
--   número total de pedidos realizados en ese mes.
--
-- - pedidos_entregados:
--   número de pedidos de ese mes que fueron entregados.
--
-- - pedidos_retrasados:
--   número de pedidos entregados con retraso.
--
-- - tasa_mensual_retrasos:
--   porcentaje de pedidos retrasados sobre pedidos entregados.
--
-- - tiempo_medio_entrega_dias:
--   tiempo medio de entrega de los pedidos entregados.
--
-- - dias_medios_retraso:
--   días medios de retraso considerando solo pedidos retrasados.
--
-- - coste_medio_envio:
--   coste medio de envío de los pedidos entregados.
--
-- - review_score_medio:
--   puntuación media de review de los pedidos entregados.
-- ============================================================

WITH monthly_orders AS (
    SELECT
        f.order_id,
        f.order_status,
        f.is_delayed,
        f.total_delivery_time_days,
        f.delay_days,
        f.total_freight_value,
        f.avg_review_score,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS order_month

    FROM analytics.fact_orders AS f
    INNER JOIN core.orders AS o
        ON f.order_id = o.order_id

    WHERE o.order_purchase_timestamp IS NOT NULL
)

SELECT
    order_month,

    TO_CHAR(
        order_month,
        'YYYY-MM'
    ) AS order_month_label,

    COUNT(DISTINCT order_id) AS total_pedidos,

    COUNT(DISTINCT order_id) FILTER (
        WHERE order_status = 'delivered'
    ) AS pedidos_entregados,

    COUNT(DISTINCT order_id) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
    ) AS pedidos_retrasados,

    ROUND(
        COUNT(DISTINCT order_id) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(DISTINCT order_id) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed IS NOT NULL
            ),
            0
        ) * 100,
        2
    ) AS tasa_mensual_retrasos,

    ROUND(
        AVG(total_delivery_time_days) FILTER (
            WHERE order_status = 'delivered'
              AND total_delivery_time_days IS NOT NULL
        )::numeric,
        2
    ) AS tiempo_medio_entrega_dias,

    ROUND(
        AVG(delay_days) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND delay_days IS NOT NULL
        )::numeric,
        2
    ) AS dias_medios_retraso,

    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE order_status = 'delivered'
              AND total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio,

    ROUND(
        AVG(avg_review_score) FILTER (
            WHERE order_status = 'delivered'
              AND avg_review_score IS NOT NULL
        )::numeric,
        2
    ) AS review_score_medio

FROM monthly_orders

GROUP BY order_month

ORDER BY order_month;