-- ============================================================
-- 08_delay_by_geography.sql
-- Rendimiento logístico por localización geográfica
-- ============================================================
-- Objetivo:
-- Este script analiza si existen diferencias logísticas según
-- la localización geográfica del cliente y del vendedor.
--
-- Indicadores calculados:
-- - Total de pedidos por estado del cliente.
-- - Porcentaje de retraso por estado del cliente.
-- - Tiempo medio de entrega por estado del cliente.
-- - Coste medio de envío por estado del cliente.
-- - Comparación entre estado del cliente y estado del vendedor.
--
-- Tablas utilizadas:
-- - analytics.fact_orders
-- - analytics.fact_order_items
-- - analytics.dim_customer
-- - analytics.dim_seller
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - is_delayed = true indica que el pedido fue entregado con retraso.
-- - Se excluyen registros con is_delayed IS NULL porque no pueden
--   clasificarse de forma segura como retrasados o no retrasados.
-- - Se utiliza COUNT(DISTINCT order_id) para evitar duplicidades
--   cuando un pedido tiene varias líneas o varios vendedores.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Rendimiento logístico por estado del cliente
-- ============================================================
-- Esta consulta resume los principales indicadores logísticos
-- agrupados por el estado del cliente.
--
-- Interpretación:
-- - total_pedidos:
--   número total de pedidos entregados asociados a clientes de ese estado.
--
-- - total_pedidos_retrasados:
--   número de pedidos entregados con retraso en ese estado.
--
-- - porcentaje_retraso:
--   porcentaje de pedidos retrasados sobre el total de pedidos entregados
--   del estado.
--
-- - tiempo_medio_entrega_dias:
--   tiempo medio entre la compra y la entrega del pedido.
--
-- - coste_medio_envio:
--   coste medio de envío de los pedidos asociados a ese estado.
-- ============================================================

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS total_pedidos,

    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.is_delayed = true
    ) AS total_pedidos_retrasados,

    ROUND(
        COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(DISTINCT o.order_id),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso,

    ROUND(
        AVG(o.total_delivery_time_days) FILTER (
            WHERE o.total_delivery_time_days IS NOT NULL
        )::numeric,
        2
    ) AS tiempo_medio_entrega_dias,

    ROUND(
        AVG(o.total_freight_value) FILTER (
            WHERE o.total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio

FROM analytics.fact_orders AS o
INNER JOIN analytics.dim_customer AS c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'
  AND o.is_delayed IS NOT NULL

GROUP BY c.customer_state
ORDER BY porcentaje_retraso DESC;


-- ============================================================
-- 2. Comparación entre estado del cliente y estado del vendedor
-- ============================================================
-- Esta consulta compara el estado del cliente con el estado del
-- vendedor para analizar si los pedidos interestatales presentan
-- diferencias logísticas respecto a los pedidos dentro del mismo estado.
--
-- Interpretación:
-- - customer_state:
--   estado del cliente.
--
-- - seller_state:
--   estado del vendedor.
--
-- - same_state_order:
--   indica si cliente y vendedor pertenecen al mismo estado.
--
-- - total_pedidos:
--   número de pedidos distintos asociados a esa combinación geográfica.
--
-- - porcentaje_retraso:
--   porcentaje de pedidos retrasados dentro de la combinación.
--
-- - tiempo_medio_entrega_dias:
--   tiempo medio de entrega para esa combinación.
--
-- - coste_medio_envio:
--   coste medio de envío para esa combinación.
-- ============================================================

WITH order_seller_state AS (
    SELECT DISTINCT
        o.order_id,
        c.customer_state,
        s.seller_state,
        o.is_delayed,
        o.total_delivery_time_days,
        o.total_freight_value

    FROM analytics.fact_orders AS o
    INNER JOIN analytics.dim_customer AS c
        ON o.customer_id = c.customer_id
    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id
    INNER JOIN analytics.dim_seller AS s
        ON i.seller_id = s.seller_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL
)

SELECT
    customer_state,
    seller_state,

    CASE
        WHEN customer_state = seller_state THEN 'Mismo estado'
        ELSE 'Distinto estado'
    END AS same_state_order,

    COUNT(DISTINCT order_id) AS total_pedidos,

    COUNT(DISTINCT order_id) FILTER (
        WHERE is_delayed = true
    ) AS total_pedidos_retrasados,

    ROUND(
        COUNT(DISTINCT order_id) FILTER (
            WHERE is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(DISTINCT order_id),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso,

    ROUND(
        AVG(total_delivery_time_days) FILTER (
            WHERE total_delivery_time_days IS NOT NULL
        )::numeric,
        2
    ) AS tiempo_medio_entrega_dias,

    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio

FROM order_seller_state

GROUP BY
    customer_state,
    seller_state,
    same_state_order

HAVING
    COUNT(DISTINCT order_id) FILTER (
        WHERE is_delayed = true
    ) > 50

ORDER BY porcentaje_retraso DESC;

-- ============================================================
-- 3. Comparación agregada: mismo estado vs distinto estado
-- ============================================================
-- Esta consulta resume la comparación anterior en dos grupos:
-- pedidos donde cliente y vendedor están en el mismo estado y pedidos
-- donde están en estados distintos.
--
-- Esta versión es especialmente útil para gráficos o tarjetas resumen
-- en Power BI.
-- ============================================================

WITH order_seller_state AS (
    SELECT DISTINCT
        o.order_id,
        c.customer_state,
        s.seller_state,
        o.is_delayed,
        o.total_delivery_time_days,
        o.total_freight_value

    FROM analytics.fact_orders AS o
    INNER JOIN analytics.dim_customer AS c
        ON o.customer_id = c.customer_id
    INNER JOIN analytics.fact_order_items AS i
        ON o.order_id = i.order_id
    INNER JOIN analytics.dim_seller AS s
        ON i.seller_id = s.seller_id

    WHERE o.order_status = 'delivered'
      AND o.is_delayed IS NOT NULL
)

SELECT
    CASE
        WHEN customer_state = seller_state THEN 'Mismo estado'
        ELSE 'Distinto estado'
    END AS same_state_order,

    COUNT(DISTINCT order_id) AS total_pedidos,

    COUNT(DISTINCT order_id) FILTER (
        WHERE is_delayed = true
    ) AS total_pedidos_retrasados,

    ROUND(
        COUNT(DISTINCT order_id) FILTER (
            WHERE is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(DISTINCT order_id),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso,

    ROUND(
        AVG(total_delivery_time_days) FILTER (
            WHERE total_delivery_time_days IS NOT NULL
        )::numeric,
        2
    ) AS tiempo_medio_entrega_dias,

    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio

FROM order_seller_state

GROUP BY same_state_order
ORDER BY porcentaje_retraso DESC;