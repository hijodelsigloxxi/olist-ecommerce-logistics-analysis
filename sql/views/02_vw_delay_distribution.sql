-- ============================================================
-- 02_vw_delay_distribution.sql
-- Vistas de distribución de retrasos
-- ============================================================
-- Objetivo:
-- Crear vistas reutilizables para Power BI relacionadas con la
-- distribución de retrasos en los pedidos entregados.
--
-- Vistas creadas:
-- - analytics.vw_delay_distribution_delivered
-- - analytics.vw_delay_distribution_delayed
--
-- Tablas utilizadas:
-- - analytics.fact_orders
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - delay_days <= 0 indica que el pedido fue entregado en plazo
--   o antes de la fecha estimada.
-- - delay_days > 0 indica que el pedido fue entregado con retraso.
-- - La primera vista calcula la distribución sobre todos los pedidos
--   entregados.
-- - La segunda vista calcula la distribución solo sobre pedidos
--   retrasados.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Vista para Power BI: distribución sobre pedidos entregados
-- ============================================================
-- Esta vista resume la distribución de los pedidos entregados según
-- si llegaron en plazo o con distintos niveles de retraso.
--
-- Interpretación:
-- El total de referencia son todos los pedidos entregados.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_distribution_delivered AS
SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS total_entregados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days <= 0
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS en_plazo,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 0
              AND delay_days <= 3
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS "0a3_dias_tarde",

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 3
              AND delay_days <= 7
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS "3a7_dias_tarde",

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 7
              AND delay_days <= 12
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS "7a12_dias_tarde",

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 12
              AND delay_days <= 17
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS "12a17_dias_tarde",

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 17
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS "mas_de_17_dias_tarde"

FROM analytics.fact_orders;


-- ============================================================
-- 2. Vista para Power BI: distribución sobre pedidos retrasados
-- ============================================================
-- Esta vista resume la distribución de los pedidos retrasados según
-- la duración del retraso.
--
-- Interpretación:
-- El total de referencia son únicamente los pedidos entregados
-- con delay_days > 0.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delay_distribution_delayed AS
SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND delay_days > 0
    ) AS total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 0
              AND delay_days <= 3
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND delay_days > 0
            ),
            0
        ) * 100,
        2
    ) AS "0a3_dias_tarde",

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 3
              AND delay_days <= 7
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND delay_days > 0
            ),
            0
        ) * 100,
        2
    ) AS "3a7_dias_tarde",

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 7
              AND delay_days <= 12
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND delay_days > 0
            ),
            0
        ) * 100,
        2
    ) AS "7a12_dias_tarde",

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 12
              AND delay_days <= 17
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND delay_days > 0
            ),
            0
        ) * 100,
        2
    ) AS "12a17_dias_tarde",

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 17
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND delay_days > 0
            ),
            0
        ) * 100,
        2
    ) AS "mas_de_17_dias_tarde"

FROM analytics.fact_orders;


-- ============================================================
-- 3. Comprobación de vistas creadas
-- ============================================================

SELECT *
FROM analytics.vw_delay_distribution_delivered;

SELECT *
FROM analytics.vw_delay_distribution_delayed;