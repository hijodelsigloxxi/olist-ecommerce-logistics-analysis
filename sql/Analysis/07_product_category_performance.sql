-- ============================================================
-- 07_delay_by_product_category.sql
-- Rendimiento logístico por categoría de producto
-- ============================================================
-- Objetivo:
-- Este script analiza si existen diferencias logísticas entre
-- categorías de producto.
--
-- Indicadores calculados:
-- - Total de líneas de pedido por categoría.
-- - Total de pedidos asociados a cada categoría.
-- - Porcentaje de retraso por categoría.
-- - Tiempo medio de entrega por categoría.
-- - Coste medio de envío por categoría.
-- - Review score medio por categoría.
--
-- Tablas utilizadas:
-- - analytics.fact_orders
-- - analytics.fact_order_items
-- - analytics.dim_product
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - El total de líneas de pedido se calcula a partir de
--   analytics.fact_order_items.
-- - El total de pedidos se calcula con COUNT(DISTINCT order_id)
--   para evitar duplicaciones cuando un pedido tiene varias líneas.
-- - El porcentaje de retraso se calcula sobre pedidos entregados
--   asociados a cada categoría.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Rendimiento logístico por categoría de producto
-- ============================================================
-- Esta consulta resume los principales indicadores logísticos
-- agrupados por categoría de producto.
--
-- Interpretación:
-- - total_lineas_pedido:
--   número total de líneas de pedido asociadas a la categoría.
--
-- - total_pedidos:
--   número de pedidos distintos asociados a la categoría.
--
-- - porcentaje_retraso:
--   porcentaje de pedidos entregados con retraso dentro de la categoría.
--
-- - tiempo_medio_entrega_dias:
--   tiempo medio entre la compra y la entrega del pedido.
--
-- - coste_medio_envio:
--   coste medio de envío de los pedidos asociados a la categoría.
--
-- - review_score_medio:
--   valoración media de los pedidos asociados a la categoría.
-- ============================================================


WITH order_category_lines AS (
    SELECT
        i.order_id,
        i.order_item_id,

        COALESCE(
            p.product_category_name,
            'Sin categoría'
        ) AS product_category

    FROM analytics.fact_order_items AS i
    INNER JOIN analytics.dim_product AS p
        ON i.product_id = p.product_id
),

category_line_counts AS (
    SELECT
        product_category,
        COUNT(*) AS total_lineas_pedido
    FROM order_category_lines
    GROUP BY product_category
),

order_category AS (
    SELECT DISTINCT
        order_id,
        product_category
    FROM order_category_lines
),

category_order_metrics AS (
    SELECT
        oc.product_category,
        o.order_id,
        o.is_delayed,
        o.total_delivery_time_days,
        o.total_freight_value,
        o.avg_review_score

    FROM order_category AS oc
    INNER JOIN analytics.fact_orders AS o
        ON oc.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL
)

SELECT
    com.product_category,

    clc.total_lineas_pedido,

    COUNT(DISTINCT com.order_id) AS total_pedidos,

    COUNT(DISTINCT com.order_id) FILTER (
        WHERE com.is_delayed = true
    ) AS total_pedidos_retrasados,

    ROUND(
        COUNT(DISTINCT com.order_id) FILTER (
            WHERE com.is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(DISTINCT com.order_id),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso,

    ROUND(
        AVG(com.total_delivery_time_days) FILTER (
            WHERE com.total_delivery_time_days IS NOT NULL
        )::numeric,
        2
    ) AS tiempo_medio_entrega_dias,

    ROUND(
        AVG(com.total_freight_value) FILTER (
            WHERE com.total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio,

    ROUND(
        AVG(com.avg_review_score) FILTER (
            WHERE com.avg_review_score IS NOT NULL
        )::numeric,
        2
    ) AS review_score_medio

FROM category_order_metrics AS com
INNER JOIN category_line_counts AS clc
    ON com.product_category = clc.product_category

GROUP BY
    com.product_category,
    clc.total_lineas_pedido

ORDER BY porcentaje_retraso DESC;