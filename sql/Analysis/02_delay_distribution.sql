-- ============================================================
-- 02_delay_distribution.sql
-- Distribución de los pedidos según el tiempo de retraso
-- ============================================================
-- Objetivo:
-- Este script analiza cómo se distribuyen los pedidos entregados
-- según su cumplimiento respecto a la fecha estimada de entrega.
--
-- Además de calcular porcentajes por tramo de retraso, también
-- calcula métricas asociadas a cada tramo:
-- - review score medio
-- - valor medio del pedido
-- - coste medio de envío
--
-- Tabla principal:
-- analytics.fact_orders
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - delay_days <= 0 significa que el pedido fue entregado en plazo
--   o antes de la fecha estimada.
-- - delay_days > 0 significa que el pedido fue entregado con retraso.
-- - Como delay_days puede tener valores decimales, se utilizan rangos
--   abiertos y cerrados en lugar de BETWEEN.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Distribución de pedidos entregados según cumplimiento del plazo
-- ============================================================
-- Esta consulta calcula el porcentaje de pedidos entregados en plazo
-- y de pedidos retrasados por tramos de días sobre el total de pedidos
-- entregados.
--
-- Denominador:
-- Total de pedidos entregados.
--
-- Interpretación:
-- Cada porcentaje representa qué proporción del total de pedidos
-- entregados cae en cada tramo de cumplimiento o retraso.
-- ============================================================

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
-- 2. Distribución de pedidos retrasados por tramo de retraso
-- ============================================================
-- Esta consulta calcula cómo se distribuyen los pedidos retrasados
-- según la gravedad del retraso.
--
-- Denominador:
-- Total de pedidos entregados con retraso.
--
-- Interpretación:
-- Cada porcentaje representa qué proporción de los pedidos retrasados
-- pertenece a cada tramo de retraso.
--
-- A diferencia de la consulta anterior, aquí no se incluyen los pedidos
-- entregados en plazo, porque el análisis se limita solo a los pedidos
-- que llegaron tarde.
-- ============================================================

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
-- 3. Review score medio por tramo de retraso
-- ============================================================
-- Esta consulta calcula la valoración media del cliente según
-- el tramo de entrega o retraso.
--
-- Variable analizada:
-- avg_review_score
--
-- Interpretación:
-- Permite observar si los pedidos entregados tarde tienen una
-- peor valoración media que los pedidos entregados en plazo.
-- ============================================================

SELECT
    ROUND(
        AVG(avg_review_score) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days <= 0
              AND avg_review_score IS NOT NULL
        )::numeric,
        2
    ) AS media_review_en_plazo,

    ROUND(
        AVG(avg_review_score) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 0
              AND delay_days <= 3
              AND avg_review_score IS NOT NULL
        )::numeric,
        2
    ) AS media_review_0a3_dias_tarde,

    ROUND(
        AVG(avg_review_score) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 3
              AND delay_days <= 7
              AND avg_review_score IS NOT NULL
        )::numeric,
        2
    ) AS media_review_3a7_dias_tarde,

    ROUND(
        AVG(avg_review_score) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 7
              AND delay_days <= 12
              AND avg_review_score IS NOT NULL
        )::numeric,
        2
    ) AS media_review_7a12_dias_tarde,

    ROUND(
        AVG(avg_review_score) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 12
              AND delay_days <= 17
              AND avg_review_score IS NOT NULL
        )::numeric,
        2
    ) AS media_review_12a17_dias_tarde,

    ROUND(
        AVG(avg_review_score) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 17
              AND avg_review_score IS NOT NULL
        )::numeric,
        2
    ) AS media_review_mas_de_17_dias_tarde

FROM analytics.fact_orders;


-- ============================================================
-- 4. Valor medio del pedido por tramo de retraso
-- ============================================================
-- Esta consulta calcula el valor medio pagado por pedido según
-- el tramo de entrega o retraso.
--
-- Variable analizada:
-- total_payment_value
--
-- Interpretación:
-- Permite observar si los pedidos de mayor o menor valor tienden
-- a concentrarse en determinados niveles de retraso.
-- ============================================================

SELECT
    ROUND(
        AVG(total_payment_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days <= 0
              AND total_payment_value IS NOT NULL
        )::numeric,
        2
    ) AS valor_medio_en_plazo,

    ROUND(
        AVG(total_payment_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 0
              AND delay_days <= 3
              AND total_payment_value IS NOT NULL
        )::numeric,
        2
    ) AS valor_medio_0a3_dias_tarde,

    ROUND(
        AVG(total_payment_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 3
              AND delay_days <= 7
              AND total_payment_value IS NOT NULL
        )::numeric,
        2
    ) AS valor_medio_3a7_dias_tarde,

    ROUND(
        AVG(total_payment_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 7
              AND delay_days <= 12
              AND total_payment_value IS NOT NULL
        )::numeric,
        2
    ) AS valor_medio_7a12_dias_tarde,

    ROUND(
        AVG(total_payment_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 12
              AND delay_days <= 17
              AND total_payment_value IS NOT NULL
        )::numeric,
        2
    ) AS valor_medio_12a17_dias_tarde,

    ROUND(
        AVG(total_payment_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 17
              AND total_payment_value IS NOT NULL
        )::numeric,
        2
    ) AS valor_medio_mas_de_17_dias_tarde

FROM analytics.fact_orders;


-- ============================================================
-- 5. Coste medio de envío por tramo de retraso
-- ============================================================
-- Esta consulta calcula el coste medio de envío según el tramo
-- de entrega o retraso.
--
-- Variable analizada:
-- total_freight_value
--
-- Interpretación:
-- Permite observar si los pedidos con mayor coste de envío tienden
-- a concentrarse en determinados niveles de retraso.
-- ============================================================

SELECT
    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days <= 0
              AND total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio_en_plazo,

    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 0
              AND delay_days <= 3
              AND total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio_0a3_dias_tarde,

    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 3
              AND delay_days <= 7
              AND total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio_3a7_dias_tarde,

    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 7
              AND delay_days <= 12
              AND total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio_7a12_dias_tarde,

    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 12
              AND delay_days <= 17
              AND total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio_12a17_dias_tarde,

    ROUND(
        AVG(total_freight_value) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days > 17
              AND total_freight_value IS NOT NULL
        )::numeric,
        2
    ) AS coste_medio_envio_mas_de_17_dias_tarde

FROM analytics.fact_orders;


