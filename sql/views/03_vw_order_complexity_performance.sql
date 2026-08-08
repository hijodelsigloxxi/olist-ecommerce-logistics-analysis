-- ============================================================
-- 03_vw_order_complexity_performance.sql
-- Vistas de rendimiento logístico según complejidad del pedido
-- ============================================================
-- Objetivo:
-- Crear vistas reutilizables para Power BI que permitan analizar
-- si la complejidad del pedido se relaciona con la probabilidad
-- de retraso logístico.
--
-- La complejidad se analiza a partir de:
-- - number_of_items
-- - number_of_products
-- - number_of_sellers
--
-- Vistas creadas:
-- - analytics.vw_delay_by_items_bucket
-- - analytics.vw_delay_by_products_bucket
-- - analytics.vw_delay_by_sellers_bucket
--
-- Tabla principal:
-- - analytics.fact_orders
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - Se excluyen registros con is_delayed IS NULL porque no pueden
--   clasificarse de forma segura como retrasados o no retrasados.
-- - porcentaje_sobre_total_retrasados indica qué proporción de todos
--   los pedidos retrasados pertenece a ese tramo.
-- - porcentaje_retraso_dentro_tramo indica qué proporción de los pedidos
--   del tramo se retrasó.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Vista: retrasos según número de ítems del pedido
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_by_items_bucket AS
WITH items_base AS (
    SELECT
        order_id,
        is_delayed,

        CASE
            WHEN number_of_items = 1 THEN '1 item'
            WHEN number_of_items = 2 THEN '2 items'
            WHEN number_of_items = 3 THEN '3 items'
            WHEN number_of_items = 4 THEN '4 items'
            WHEN number_of_items >= 5 THEN '5 o más items'
        END AS complexity_bucket,

        CASE
            WHEN number_of_items = 1 THEN 1
            WHEN number_of_items = 2 THEN 2
            WHEN number_of_items = 3 THEN 3
            WHEN number_of_items = 4 THEN 4
            WHEN number_of_items >= 5 THEN 5
        END AS bucket_order

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND is_delayed IS NOT NULL
      AND number_of_items IS NOT NULL
),

items_distribution AS (
    SELECT
        complexity_bucket,
        bucket_order,

        COUNT(*) AS total_pedidos,

        COUNT(*) FILTER (
            WHERE is_delayed = true
        ) AS pedidos_retrasados

    FROM items_base

    WHERE complexity_bucket IS NOT NULL

    GROUP BY
        complexity_bucket,
        bucket_order
)

SELECT
    complexity_bucket,
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

FROM items_distribution

ORDER BY bucket_order;


-- ============================================================
-- 2. Vista: retrasos según número de productos distintos
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_by_products_bucket AS
WITH products_base AS (
    SELECT
        order_id,
        is_delayed,

        CASE
            WHEN number_of_products = 1 THEN '1 producto'
            WHEN number_of_products = 2 THEN '2 productos'
            WHEN number_of_products = 3 THEN '3 productos'
            WHEN number_of_products = 4 THEN '4 productos'
            WHEN number_of_products >= 5 THEN '5 o más productos'
        END AS complexity_bucket,

        CASE
            WHEN number_of_products = 1 THEN 1
            WHEN number_of_products = 2 THEN 2
            WHEN number_of_products = 3 THEN 3
            WHEN number_of_products = 4 THEN 4
            WHEN number_of_products >= 5 THEN 5
        END AS bucket_order

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND is_delayed IS NOT NULL
      AND number_of_products IS NOT NULL
),

products_distribution AS (
    SELECT
        complexity_bucket,
        bucket_order,

        COUNT(*) AS total_pedidos,

        COUNT(*) FILTER (
            WHERE is_delayed = true
        ) AS pedidos_retrasados

    FROM products_base

    WHERE complexity_bucket IS NOT NULL

    GROUP BY
        complexity_bucket,
        bucket_order
)

SELECT
    complexity_bucket,
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

FROM products_distribution

ORDER BY bucket_order;


-- ============================================================
-- 3. Vista: retrasos según número de vendedores del pedido
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_by_sellers_bucket AS
WITH sellers_base AS (
    SELECT
        order_id,
        is_delayed,

        CASE
            WHEN number_of_sellers = 1 THEN '1 vendedor'
            WHEN number_of_sellers = 2 THEN '2 vendedores'
            WHEN number_of_sellers = 3 THEN '3 vendedores'
            WHEN number_of_sellers = 4 THEN '4 vendedores'
            WHEN number_of_sellers >= 5 THEN '5 o más vendedores'
        END AS complexity_bucket,

        CASE
            WHEN number_of_sellers = 1 THEN 1
            WHEN number_of_sellers = 2 THEN 2
            WHEN number_of_sellers = 3 THEN 3
            WHEN number_of_sellers = 4 THEN 4
            WHEN number_of_sellers >= 5 THEN 5
        END AS bucket_order

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND is_delayed IS NOT NULL
      AND number_of_sellers IS NOT NULL
),

sellers_distribution AS (
    SELECT
        complexity_bucket,
        bucket_order,

        COUNT(*) AS total_pedidos,

        COUNT(*) FILTER (
            WHERE is_delayed = true
        ) AS pedidos_retrasados

    FROM sellers_base

    WHERE complexity_bucket IS NOT NULL

    GROUP BY
        complexity_bucket,
        bucket_order
)

SELECT
    complexity_bucket,
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

FROM sellers_distribution

ORDER BY bucket_order;


-- ============================================================
-- 4. Comprobación de vistas creadas
-- ============================================================

SELECT *
FROM analytics.vw_delay_by_items_bucket;

SELECT *
FROM analytics.vw_delay_by_products_bucket;

SELECT *
FROM analytics.vw_delay_by_sellers_bucket;