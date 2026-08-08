-- ============================================================
-- 10_vw_monthly_logistics_trends.sql
-- Vista de evolución mensual del rendimiento logístico
-- ============================================================
-- Objetivo:
-- Crear una vista reutilizable para Power BI que permita analizar
-- la evolución mensual de los principales indicadores logísticos
-- del marketplace.
--
-- Métricas calculadas:
-- - Pedidos por mes.
-- - Pedidos entregados por mes.
-- - Pedidos retrasados por mes.
-- - Tasa mensual de retrasos.
-- - Tiempo medio mensual de entrega.
-- - Días medios de retraso por mes.
-- - Coste medio mensual de envío.
-- - Review score medio mensual.
--
-- Vista creada:
-- analytics.vw_monthly_logistics_trends
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

CREATE OR REPLACE VIEW analytics.vw_monthly_logistics_trends AS
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

GROUP BY
    order_month

ORDER BY
    order_month;


-- ============================================================
-- Comprobación de la vista creada
-- ============================================================

SELECT *
FROM analytics.vw_monthly_logistics_trends;