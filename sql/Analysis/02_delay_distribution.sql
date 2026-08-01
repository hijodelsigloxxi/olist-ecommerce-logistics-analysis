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


-- ============================================================
-- 6. Vista para Power BI: distribución sobre pedidos entregados
-- ============================================================
-- Esta vista resume la distribución de todos los pedidos entregados
-- según si fueron entregados en plazo o con distintos niveles de retraso.
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
-- 7. Vista para Power BI: distribución sobre pedidos retrasados
-- ============================================================
-- Esta vista resume la distribución de los pedidos retrasados según
-- la duración del retraso.
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
-- 8. Vista para Power BI: review score medio por tramo
-- ============================================================
-- Esta vista organiza la valoración media por tramo de retraso
-- en formato vertical, más adecuado para gráficos de barras.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_review_score_by_delay_bucket AS
SELECT
    delay_bucket,
    bucket_order,
    COUNT(*) AS total_orders,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score
FROM (
    SELECT
        order_id,
        avg_review_score,
        CASE
            WHEN delay_days <= 0 THEN 'En plazo'
            WHEN delay_days > 0 AND delay_days <= 3 THEN '0-3 días tarde'
            WHEN delay_days > 3 AND delay_days <= 7 THEN '3-7 días tarde'
            WHEN delay_days > 7 AND delay_days <= 12 THEN '7-12 días tarde'
            WHEN delay_days > 12 AND delay_days <= 17 THEN '12-17 días tarde'
            WHEN delay_days > 17 THEN 'Más de 17 días tarde'
        END AS delay_bucket,
        CASE
            WHEN delay_days <= 0 THEN 1
            WHEN delay_days > 0 AND delay_days <= 3 THEN 2
            WHEN delay_days > 3 AND delay_days <= 7 THEN 3
            WHEN delay_days > 7 AND delay_days <= 12 THEN 4
            WHEN delay_days > 12 AND delay_days <= 17 THEN 5
            WHEN delay_days > 17 THEN 6
        END AS bucket_order
    FROM analytics.fact_orders
    WHERE order_status = 'delivered'
      AND delay_days IS NOT NULL
      AND avg_review_score IS NOT NULL
) t
GROUP BY delay_bucket, bucket_order
ORDER BY bucket_order;


-- ============================================================
-- 9. Vista para Power BI: valor medio del pedido por tramo
-- ============================================================
-- Esta vista organiza el valor medio del pedido por tramo de retraso
-- en formato vertical, más adecuado para gráficos de barras.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_order_value_by_delay_bucket AS
SELECT
    delay_bucket,
    bucket_order,
    COUNT(*) AS total_orders,
    ROUND(AVG(total_payment_value)::numeric, 2) AS avg_total_payment_value
FROM (
    SELECT
        order_id,
        total_payment_value,
        CASE
            WHEN delay_days <= 0 THEN 'En plazo'
            WHEN delay_days > 0 AND delay_days <= 3 THEN '0-3 días tarde'
            WHEN delay_days > 3 AND delay_days <= 7 THEN '3-7 días tarde'
            WHEN delay_days > 7 AND delay_days <= 12 THEN '7-12 días tarde'
            WHEN delay_days > 12 AND delay_days <= 17 THEN '12-17 días tarde'
            WHEN delay_days > 17 THEN 'Más de 17 días tarde'
        END AS delay_bucket,
        CASE
            WHEN delay_days <= 0 THEN 1
            WHEN delay_days > 0 AND delay_days <= 3 THEN 2
            WHEN delay_days > 3 AND delay_days <= 7 THEN 3
            WHEN delay_days > 7 AND delay_days <= 12 THEN 4
            WHEN delay_days > 12 AND delay_days <= 17 THEN 5
            WHEN delay_days > 17 THEN 6
        END AS bucket_order
    FROM analytics.fact_orders
    WHERE order_status = 'delivered'
      AND delay_days IS NOT NULL
      AND total_payment_value IS NOT NULL
) t
GROUP BY delay_bucket, bucket_order
ORDER BY bucket_order;


-- ============================================================
-- 10. Vista para Power BI: coste medio de envío por tramo
-- ============================================================
-- Esta vista organiza el coste medio de envío por tramo de retraso
-- en formato vertical, más adecuado para gráficos de barras.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_freight_cost_by_delay_bucket AS
SELECT
    delay_bucket,
    bucket_order,
    COUNT(*) AS total_orders,
    ROUND(AVG(total_freight_value)::numeric, 2) AS avg_total_freight_value
FROM (
    SELECT
        order_id,
        total_freight_value,
        CASE
            WHEN delay_days <= 0 THEN 'En plazo'
            WHEN delay_days > 0 AND delay_days <= 3 THEN '0-3 días tarde'
            WHEN delay_days > 3 AND delay_days <= 7 THEN '3-7 días tarde'
            WHEN delay_days > 7 AND delay_days <= 12 THEN '7-12 días tarde'
            WHEN delay_days > 12 AND delay_days <= 17 THEN '12-17 días tarde'
            WHEN delay_days > 17 THEN 'Más de 17 días tarde'
        END AS delay_bucket,
        CASE
            WHEN delay_days <= 0 THEN 1
            WHEN delay_days > 0 AND delay_days <= 3 THEN 2
            WHEN delay_days > 3 AND delay_days <= 7 THEN 3
            WHEN delay_days > 7 AND delay_days <= 12 THEN 4
            WHEN delay_days > 12 AND delay_days <= 17 THEN 5
            WHEN delay_days > 17 THEN 6
        END AS bucket_order
    FROM analytics.fact_orders
    WHERE order_status = 'delivered'
      AND delay_days IS NOT NULL
      AND total_freight_value IS NOT NULL
) t
GROUP BY delay_bucket, bucket_order
ORDER BY bucket_order;


-- ============================================================
-- 11. Comprobación de vistas creadas
-- ============================================================

SELECT *
FROM analytics.vw_delay_distribution_delivered;

SELECT *
FROM analytics.vw_delay_distribution_delayed;

SELECT *
FROM analytics.vw_review_score_by_delay_bucket;

SELECT *
FROM analytics.vw_order_value_by_delay_bucket;

SELECT *
FROM analytics.vw_freight_cost_by_delay_bucket;