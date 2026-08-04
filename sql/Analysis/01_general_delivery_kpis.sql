-- ============================================================
-- 01_general_delivery_kpis.sql
-- Indicadores generales de rendimiento logístico
-- ============================================================
-- Objetivo:
-- Este script calcula los principales indicadores generales
-- utilizados para evaluar el rendimiento logístico del marketplace
-- de Olist.
--
-- Tabla principal:
-- analytics.fact_orders
--
-- Notas:
-- - Los indicadores relacionados con retrasos se calculan solo
--   sobre pedidos entregados.
-- - approval_time_days está almacenado en días, pero se convierte
--   a horas para facilitar su interpretación.
-- - Los tiempos de entrega y de retraso se mantienen en días.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric antes de ROUND cuando el valor procede
--   de columnas double precision.
-- ============================================================


-- ============================================================
-- 1. Número total de pedidos
-- ============================================================

SELECT 
    COUNT(*) AS total_orders
FROM analytics.fact_orders;


-- ============================================================
-- 2. Número total de pedidos entregados
-- ============================================================

SELECT 
    COUNT(*) AS delivered_orders
FROM analytics.fact_orders
WHERE order_status = 'delivered';


-- ============================================================
-- 3. Número total de pedidos entregados con retraso
-- ============================================================

SELECT 
    COUNT(*) AS delayed_orders
FROM analytics.fact_orders
WHERE order_status = 'delivered'
  AND is_delayed = true;


-- ============================================================
-- 4. Porcentaje de pedidos retrasados sobre pedidos entregados
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
    ) AS delayed_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS delayed_percentage
FROM analytics.fact_orders;


-- ============================================================
-- 5. Tiempo medio de aprobación
-- ============================================================
-- La variable approval_time_days está almacenada en días.
-- Se multiplica por 24 para expresar el resultado en horas.

SELECT
    ROUND(
        AVG(approval_time_days * 24)::numeric,
        2
    ) AS avg_approval_time_hours
FROM analytics.fact_orders
WHERE approval_time_days IS NOT NULL;


-- ============================================================
-- 6. Tiempo medio total de entrega
-- ============================================================
-- Se calcula solo para pedidos entregados.

SELECT
    ROUND(
        AVG(total_delivery_time_days)::numeric,
        2
    ) AS avg_total_delivery_time_days
FROM analytics.fact_orders
WHERE order_status = 'delivered'
  AND total_delivery_time_days IS NOT NULL;


-- ============================================================
-- 7. Días medios de retraso
-- ============================================================
-- Se calcula solo para pedidos entregados que llegaron tarde.

SELECT
    ROUND(
        AVG(delay_days)::numeric,
        2
    ) AS avg_delay_days
FROM analytics.fact_orders
WHERE order_status = 'delivered'
  AND is_delayed = true
  AND delay_days IS NOT NULL;


-- ============================================================
-- 8. Porcentaje de pedidos entregados antes de la fecha estimada
-- ============================================================
-- delay_days < 0 significa que el pedido se entregó antes de
-- la fecha estimada de entrega.

SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND delay_days < 0
    ) AS early_delivered_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days < 0
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS early_delivery_percentage
FROM analytics.fact_orders;


-- ============================================================
-- 9. Porcentaje de pedidos entregados dentro del plazo estimado
-- ============================================================
-- delay_days <= 0 significa que el pedido se entregó en plazo
-- o antes de la fecha estimada.

SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND delay_days <= 0
    ) AS on_time_orders,

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
    ) AS on_time_percentage
FROM analytics.fact_orders;


-- ============================================================
-- 10. Resumen general de indicadores logísticos
-- ============================================================
-- Esta consulta reúne los principales indicadores en una sola
-- salida. Puede utilizarse como base para tarjetas KPI en Power BI.

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
    ) AS delayed_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS delayed_percentage,

    ROUND(
        AVG(approval_time_days * 24) FILTER (
            WHERE approval_time_days IS NOT NULL
        )::numeric,
        2
    ) AS avg_approval_time_hours,

    ROUND(
        AVG(total_delivery_time_days) FILTER (
            WHERE order_status = 'delivered'
              AND total_delivery_time_days IS NOT NULL
        )::numeric,
        2
    ) AS avg_total_delivery_time_days,

    ROUND(
        AVG(delay_days) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND delay_days IS NOT NULL
        )::numeric,
        2
    ) AS avg_delay_days,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days < 0
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS early_delivery_percentage,

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
    ) AS on_time_percentage

FROM analytics.fact_orders;


-- ============================================================
-- 11. Creación de una vista reutilizable para Power BI
-- ============================================================
-- Esta vista almacena los principales indicadores logísticos
-- generales y puede utilizarse directamente como fuente para
-- tarjetas KPI en Power BI.

CREATE OR REPLACE VIEW analytics.vw_general_order_performance AS
SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
    ) AS delayed_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS delayed_percentage,

    ROUND(
        AVG(approval_time_days * 24) FILTER (
            WHERE approval_time_days IS NOT NULL
        )::numeric,
        2
    ) AS avg_approval_time_hours,

    ROUND(
        AVG(total_delivery_time_days) FILTER (
            WHERE order_status = 'delivered'
              AND total_delivery_time_days IS NOT NULL
        )::numeric,
        2
    ) AS avg_total_delivery_time_days,

    ROUND(
        AVG(delay_days) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND delay_days IS NOT NULL
        )::numeric,
        2
    ) AS avg_delay_days,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND delay_days < 0
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
            ),
            0
        ) * 100,
        2
    ) AS early_delivery_percentage,

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
    ) AS on_time_percentage

FROM analytics.fact_orders;


-- ============================================================
-- 12. Comprobación de la vista creada
-- ============================================================

SELECT *
FROM analytics.vw_general_order_performance;