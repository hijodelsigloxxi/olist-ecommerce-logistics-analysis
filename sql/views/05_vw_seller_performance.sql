-- ============================================================
-- 05_vw_seller_performance.sql
-- Vista de rendimiento logístico por vendedor
-- ============================================================
-- Objetivo:
-- Crear una vista reutilizable para Power BI que permita analizar
-- el rendimiento logístico de cada vendedor.
--
-- Métricas calculadas:
-- - Número total de pedidos.
-- - Número de pedidos retrasados.
-- - Porcentaje de pedidos retrasados.
-- - Días medios de retraso.
-- - Tiempo medio de entrega de pedidos no retrasados.
-- - Coste medio de envío por pedido y vendedor.
-- - Puntuación media de las reseñas.
-- - Segmento de volumen del vendedor.
--
-- Vista creada:
-- analytics.vw_seller_performance
--
-- Tablas utilizadas:
-- - analytics.fact_order_items
-- - analytics.fact_orders
--
-- Notas:
-- - La CTE seller_orders genera una única fila por combinación
--   de vendedor y pedido.
-- - Esto evita duplicar las métricas del pedido cuando un vendedor
--   tiene varias líneas de producto dentro del mismo pedido.
-- - Solo se consideran pedidos entregados.
-- - Se excluyen registros con is_delayed IS NULL porque no pueden
--   clasificarse de forma segura como retrasados o no retrasados.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_seller_performance AS
WITH seller_orders AS (
    SELECT
        i.seller_id,
        i.order_id,

        SUM(i.freight_value) AS seller_freight_value

    FROM analytics.fact_order_items AS i

    GROUP BY
        i.seller_id,
        i.order_id
),

seller_metrics AS (
    SELECT
        so.seller_id,

        COUNT(o.order_id) AS numero_pedidos,

        COUNT(o.order_id) FILTER (
            WHERE o.is_delayed = true
        ) AS numero_pedidos_retrasados,

        ROUND(
            COUNT(o.order_id) FILTER (
                WHERE o.is_delayed = true
            )::numeric
            / NULLIF(
                COUNT(o.order_id),
                0
            ) * 100,
            2
        ) AS porcentaje_retrasos,

        ROUND(
            AVG(o.delay_days) FILTER (
                WHERE o.is_delayed = true
                  AND o.delay_days IS NOT NULL
            )::numeric,
            2
        ) AS dias_promedio_retraso,

        ROUND(
            AVG(o.total_delivery_time_days) FILTER (
                WHERE o.is_delayed = false
                  AND o.total_delivery_time_days IS NOT NULL
            )::numeric,
            2
        ) AS dias_promedio_entrega_sin_retraso,

        ROUND(
            AVG(so.seller_freight_value) FILTER (
                WHERE so.seller_freight_value IS NOT NULL
            )::numeric,
            2
        ) AS coste_medio_envio_por_pedido,

        ROUND(
            AVG(o.avg_review_score) FILTER (
                WHERE o.avg_review_score IS NOT NULL
            )::numeric,
            2
        ) AS puntuacion_media_resenas

    FROM seller_orders AS so

    INNER JOIN analytics.fact_orders AS o
        ON so.order_id = o.order_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL

    GROUP BY
        so.seller_id
)

SELECT
    seller_id,
    numero_pedidos,
    numero_pedidos_retrasados,
    porcentaje_retrasos,
    dias_promedio_retraso,
    dias_promedio_entrega_sin_retraso,
    coste_medio_envio_por_pedido,
    puntuacion_media_resenas,

    CASE
        WHEN numero_pedidos > 500 THEN 'Más de 500 pedidos'
        WHEN numero_pedidos > 200 THEN 'Más de 200 pedidos'
        WHEN numero_pedidos > 100 THEN 'Más de 100 pedidos'
        WHEN numero_pedidos > 50 THEN 'Más de 50 pedidos'
        ELSE '50 pedidos o menos'
    END AS volume_segment,

    CASE
        WHEN numero_pedidos > 500 THEN 4
        WHEN numero_pedidos > 200 THEN 3
        WHEN numero_pedidos > 100 THEN 2
        WHEN numero_pedidos > 50 THEN 1
        ELSE 0
    END AS volume_segment_order

FROM seller_metrics

ORDER BY
    porcentaje_retrasos DESC;


-- ============================================================
-- Comprobación de la vista creada
-- ============================================================

SELECT *
FROM analytics.vw_seller_performance;


-- ============================================================
-- Consultas de uso: vendedores por umbral de volumen
-- ============================================================

-- Vendedores con más de 50 pedidos

SELECT *
FROM analytics.vw_seller_performance
WHERE numero_pedidos > 50
ORDER BY porcentaje_retrasos DESC;


-- Vendedores con más de 100 pedidos

SELECT *
FROM analytics.vw_seller_performance
WHERE numero_pedidos > 100
ORDER BY porcentaje_retrasos DESC;


-- Vendedores con más de 200 pedidos

SELECT *
FROM analytics.vw_seller_performance
WHERE numero_pedidos > 200
ORDER BY porcentaje_retrasos DESC;


-- Vendedores con más de 500 pedidos

SELECT *
FROM analytics.vw_seller_performance
WHERE numero_pedidos > 500
ORDER BY porcentaje_retrasos DESC;