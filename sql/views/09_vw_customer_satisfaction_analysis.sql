-- ============================================================
-- 09_vw_customer_satisfaction_analysis.sql
-- Vistas de relación entre retrasos logísticos y satisfacción
-- ============================================================
-- Objetivo:
-- Crear vistas reutilizables para Power BI que permitan analizar
-- la relación entre los retrasos en la entrega y la satisfacción
-- del cliente medida mediante avg_review_score.
--
-- Métricas calculadas:
-- - Review score medio en pedidos retrasados y no retrasados.
-- - Distribución de puntuaciones por estado de entrega.
-- - Review score medio por rango de retraso.
-- - Porcentaje de reviews negativas en pedidos retrasados y no retrasados.
-- - Distribución de reviews negativas, neutras y positivas por estado
--   de entrega.
--
-- Vistas creadas:
-- - analytics.vw_review_score_by_delivery_status
-- - analytics.vw_review_score_distribution_by_delivery_status
-- - analytics.vw_review_score_by_delay_bucket
-- - analytics.vw_negative_reviews_by_delivery_status
-- - analytics.vw_review_category_by_delivery_status
--
-- Tabla principal:
-- - analytics.fact_orders
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - is_delayed = true indica que el pedido fue entregado con retraso.
-- - is_delayed = false indica que el pedido fue entregado dentro del plazo.
-- - Se excluyen registros con is_delayed IS NULL porque no pueden
--   clasificarse de forma segura como retrasados o no retrasados.
-- - Se excluyen registros con avg_review_score IS NULL cuando el análisis
--   requiere una puntuación de review.
-- - En este análisis se considera review negativa aquella con
--   avg_review_score <= 2.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Vista: review score medio por estado de entrega
-- ============================================================
-- Interpretación:
-- Permite observar si los pedidos retrasados reciben, en promedio,
-- peores valoraciones que los pedidos no retrasados.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_review_score_by_delivery_status AS
SELECT
    CASE
        WHEN is_delayed = true THEN 'Retrasado'
        WHEN is_delayed = false THEN 'No retrasado'
    END AS delivery_status,

    CASE
        WHEN is_delayed = true THEN 1
        WHEN is_delayed = false THEN 2
    END AS delivery_status_order,

    COUNT(*) AS total_pedidos,

    ROUND(
        AVG(avg_review_score)::numeric,
        2
    ) AS review_score_medio

FROM analytics.fact_orders

WHERE order_status = 'delivered'
  AND is_delayed IS NOT NULL
  AND avg_review_score IS NOT NULL

GROUP BY
    is_delayed

ORDER BY
    delivery_status_order;


-- ============================================================
-- 2. Vista: distribución de puntuaciones por estado de entrega
-- ============================================================
-- Interpretación:
-- Permite ver si los pedidos retrasados se concentran más en
-- puntuaciones bajas, como 1 o 2 estrellas.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_review_score_distribution_by_delivery_status AS
SELECT
    CASE
        WHEN is_delayed = true THEN 'Retrasado'
        WHEN is_delayed = false THEN 'No retrasado'
    END AS delivery_status,

    CASE
        WHEN is_delayed = true THEN 1
        WHEN is_delayed = false THEN 2
    END AS delivery_status_order,

    avg_review_score AS review_score,

    COUNT(*) AS total_pedidos,

    ROUND(
        COUNT(*)::numeric
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY is_delayed
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_dentro_estado_entrega

FROM analytics.fact_orders

WHERE order_status = 'delivered'
  AND is_delayed IS NOT NULL
  AND avg_review_score IS NOT NULL

GROUP BY
    is_delayed,
    avg_review_score

ORDER BY
    delivery_status_order,
    review_score;


-- ============================================================
-- 3. Vista: review score medio por rango de retraso
-- ============================================================
-- Interpretación:
-- Permite observar si la satisfacción disminuye a medida que aumenta
-- la gravedad del retraso.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_review_score_by_delay_bucket AS
WITH delay_buckets AS (
    SELECT
        order_id,
        delay_days,
        avg_review_score,

        CASE
            WHEN delay_days <= 0 THEN 'En plazo'
            WHEN delay_days > 0
             AND delay_days <= 3 THEN '0-3 días tarde'
            WHEN delay_days > 3
             AND delay_days <= 7 THEN '3-7 días tarde'
            WHEN delay_days > 7
             AND delay_days <= 12 THEN '7-12 días tarde'
            WHEN delay_days > 12
             AND delay_days <= 17 THEN '12-17 días tarde'
            WHEN delay_days > 17 THEN 'Más de 17 días tarde'
        END AS delay_bucket,

        CASE
            WHEN delay_days <= 0 THEN 1
            WHEN delay_days > 0
             AND delay_days <= 3 THEN 2
            WHEN delay_days > 3
             AND delay_days <= 7 THEN 3
            WHEN delay_days > 7
             AND delay_days <= 12 THEN 4
            WHEN delay_days > 12
             AND delay_days <= 17 THEN 5
            WHEN delay_days > 17 THEN 6
        END AS bucket_order

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND delay_days IS NOT NULL
      AND avg_review_score IS NOT NULL
)

SELECT
    delay_bucket,
    bucket_order,

    COUNT(*) AS total_pedidos,

    ROUND(
        AVG(avg_review_score)::numeric,
        2
    ) AS review_score_medio

FROM delay_buckets

WHERE delay_bucket IS NOT NULL

GROUP BY
    delay_bucket,
    bucket_order

ORDER BY
    bucket_order;


-- ============================================================
-- 4. Vista: porcentaje de reviews negativas por estado de entrega
-- ============================================================
-- Criterio:
-- Se considera review negativa aquella con avg_review_score <= 2.
--
-- Interpretación:
-- Permite comprobar si los pedidos retrasados concentran una mayor
-- proporción de valoraciones negativas.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_negative_reviews_by_delivery_status AS
SELECT
    CASE
        WHEN is_delayed = true THEN 'Retrasado'
        WHEN is_delayed = false THEN 'No retrasado'
    END AS delivery_status,

    CASE
        WHEN is_delayed = true THEN 1
        WHEN is_delayed = false THEN 2
    END AS delivery_status_order,

    COUNT(*) AS total_pedidos_con_review,

    COUNT(*) FILTER (
        WHERE avg_review_score <= 2
    ) AS total_reviews_negativas,

    ROUND(
        COUNT(*) FILTER (
            WHERE avg_review_score <= 2
        )::numeric
        / NULLIF(
            COUNT(*),
            0
        ) * 100,
        2
    ) AS porcentaje_reviews_negativas

FROM analytics.fact_orders

WHERE order_status = 'delivered'
  AND is_delayed IS NOT NULL
  AND avg_review_score IS NOT NULL

GROUP BY
    is_delayed

ORDER BY
    delivery_status_order;


-- ============================================================
-- 5. Vista: distribución de reviews negativas, neutras y positivas
-- ============================================================
-- Criterio:
-- - Negativa: avg_review_score <= 2
-- - Neutra: avg_review_score = 3
-- - Positiva: avg_review_score >= 4
--
-- Interpretación:
-- Permite comparar la estructura de satisfacción entre pedidos
-- retrasados y no retrasados.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_review_category_by_delivery_status AS
WITH review_classification AS (
    SELECT
        order_id,
        is_delayed,
        avg_review_score,

        CASE
            WHEN avg_review_score <= 2 THEN 'Negativa'
            WHEN avg_review_score = 3 THEN 'Neutra'
            WHEN avg_review_score >= 4 THEN 'Positiva'
        END AS review_category,

        CASE
            WHEN avg_review_score <= 2 THEN 1
            WHEN avg_review_score = 3 THEN 2
            WHEN avg_review_score >= 4 THEN 3
        END AS review_category_order

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND is_delayed IS NOT NULL
      AND avg_review_score IS NOT NULL
)

SELECT
    CASE
        WHEN is_delayed = true THEN 'Retrasado'
        WHEN is_delayed = false THEN 'No retrasado'
    END AS delivery_status,

    CASE
        WHEN is_delayed = true THEN 1
        WHEN is_delayed = false THEN 2
    END AS delivery_status_order,

    review_category,
    review_category_order,

    COUNT(*) AS total_pedidos,

    ROUND(
        COUNT(*)::numeric
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY is_delayed
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_dentro_estado_entrega

FROM review_classification

WHERE review_category IS NOT NULL

GROUP BY
    is_delayed,
    review_category,
    review_category_order

ORDER BY
    delivery_status_order,
    review_category_order;


-- ============================================================
-- 6. Comprobación de vistas creadas
-- ============================================================

SELECT *
FROM analytics.vw_review_score_by_delivery_status;

SELECT *
FROM analytics.vw_review_score_distribution_by_delivery_status;

SELECT *
FROM analytics.vw_review_score_by_delay_bucket;

SELECT *
FROM analytics.vw_negative_reviews_by_delivery_status;

SELECT *
FROM analytics.vw_review_category_by_delivery_status;