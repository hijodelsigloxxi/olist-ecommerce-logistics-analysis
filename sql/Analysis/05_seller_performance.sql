-- ============================================================
-- 05_seller_performance.sql
-- Rendimiento logístico por vendedor
-- ============================================================
-- Objetivo:
-- Este script analiza el rendimiento logístico de los vendedores
-- en función del número de pedidos entregados asociados a cada uno.
--
-- La CTE seller_orders genera una única fila por combinación de vendedor
-- y pedido. De este modo se evita duplicar las métricas del pedido cuando
-- un vendedor tiene varias líneas de producto dentro del mismo pedido.
--
-- Métricas calculadas:
-- - Número total de pedidos.
-- - Número de pedidos retrasados.
-- - Porcentaje de pedidos retrasados.
-- - Días medios de retraso.
-- - Tiempo medio de entrega de los pedidos no retrasados.
-- - Coste medio de envío por pedido y vendedor.
-- - Puntuación media de las reseñas.
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - Se excluyen registros con is_delayed IS NULL porque no pueden
--   clasificarse de forma segura como retrasados o no retrasados.
-- - La columna correcta de reseñas en analytics.fact_orders es
--   avg_review_score, no review_score.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================================
-- 1. VENDEDORES CON MÁS DE 50 PEDIDOS
-- ============================================================================

WITH seller_orders AS (
    SELECT
        i.seller_id,
        i.order_id,

        SUM(i.freight_value) AS seller_freight_value

    FROM analytics.fact_order_items AS i

    GROUP BY
        i.seller_id,
        i.order_id
)

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

HAVING
    COUNT(o.order_id) > 50

ORDER BY
    porcentaje_retrasos DESC;


-- ============================================================================
-- 2. VENDEDORES CON MÁS DE 100 PEDIDOS
-- ============================================================================

WITH seller_orders AS (
    SELECT
        i.seller_id,
        i.order_id,

        SUM(i.freight_value) AS seller_freight_value

    FROM analytics.fact_order_items AS i

    GROUP BY
        i.seller_id,
        i.order_id
)

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

HAVING
    COUNT(o.order_id) > 100

ORDER BY
    porcentaje_retrasos DESC;


-- ============================================================================
-- 3. VENDEDORES CON MÁS DE 200 PEDIDOS
-- ============================================================================

WITH seller_orders AS (
    SELECT
        i.seller_id,
        i.order_id,

        SUM(i.freight_value) AS seller_freight_value

    FROM analytics.fact_order_items AS i

    GROUP BY
        i.seller_id,
        i.order_id
)

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

HAVING
    COUNT(o.order_id) > 200

ORDER BY
    porcentaje_retrasos DESC;


-- ============================================================================
-- 4. VENDEDORES CON MÁS DE 500 PEDIDOS
-- ============================================================================

WITH seller_orders AS (
    SELECT
        i.seller_id,
        i.order_id,

        SUM(i.freight_value) AS seller_freight_value

    FROM analytics.fact_order_items AS i

    GROUP BY
        i.seller_id,
        i.order_id
)

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

HAVING
    COUNT(o.order_id) > 500

ORDER BY
    porcentaje_retrasos DESC;