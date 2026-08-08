-- ============================================================
-- 08_vw_geographic_delivery_analysis.sql
-- Vistas de rendimiento logístico por localización geográfica
-- ============================================================
-- Objetivo:
-- Crear vistas reutilizables para Power BI que permitan analizar
-- si existen diferencias logísticas según la localización del cliente
-- y la relación geográfica entre cliente y vendedor.
--
-- Métricas calculadas:
-- - Total de pedidos por estado del cliente.
-- - Total de pedidos retrasados por estado del cliente.
-- - Porcentaje de retraso por estado del cliente.
-- - Tiempo medio de entrega por estado del cliente.
-- - Coste medio de envío por estado del cliente.
-- - Comparación entre estado del cliente y estado del vendedor.
-- - Comparación agregada entre pedidos dentro del mismo estado y
--   pedidos entre estados distintos.
--
-- Vistas creadas:
-- - analytics.vw_customer_state_performance
-- - analytics.vw_customer_seller_state_performance
-- - analytics.vw_same_vs_different_state_performance
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
-- 1. Vista: rendimiento logístico por estado del cliente
-- ============================================================
-- Esta vista resume los principales indicadores logísticos agrupados
-- por el estado del cliente.
--
-- Interpretación:
-- Permite analizar si los pedidos enviados a determinados estados
-- presentan mayor porcentaje de retraso, mayor tiempo medio de entrega
-- o mayor coste medio de envío.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_customer_state_performance AS
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

GROUP BY
    c.customer_state

ORDER BY
    porcentaje_retraso DESC;


-- ============================================================
-- 2. Vista: comparación entre estado del cliente y estado del vendedor
-- ============================================================
-- Esta vista analiza combinaciones concretas entre estado del cliente
-- y estado del vendedor.
--
-- Interpretación:
-- Permite detectar rutas o combinaciones geográficas con mayor volumen
-- de pedidos y mayor porcentaje de retraso.
--
-- Nota:
-- Se filtran combinaciones con más de 50 pedidos retrasados para centrar
-- el análisis en rutas con volumen suficiente de incidencias.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_customer_seller_state_performance AS
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

ORDER BY
    porcentaje_retraso DESC;


-- ============================================================
-- 3. Vista: comparación agregada mismo estado vs distinto estado
-- ============================================================
-- Esta vista resume la comparación geográfica en dos grupos:
-- - Pedidos donde cliente y vendedor están en el mismo estado.
-- - Pedidos donde cliente y vendedor están en estados distintos.
--
-- Interpretación:
-- Es especialmente útil para gráficos o tarjetas resumen en Power BI,
-- porque permite comparar de forma sencilla si los pedidos interestatales
-- presentan peor rendimiento logístico.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_same_vs_different_state_performance AS
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

GROUP BY
    same_state_order

ORDER BY
    porcentaje_retraso DESC;


-- ============================================================
-- 4. Comprobación de vistas creadas
-- ============================================================

SELECT *
FROM analytics.vw_customer_state_performance;

SELECT *
FROM analytics.vw_customer_seller_state_performance;

SELECT *
FROM analytics.vw_same_vs_different_state_performance;