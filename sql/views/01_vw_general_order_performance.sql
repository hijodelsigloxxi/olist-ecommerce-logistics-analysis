-- ============================================================
-- 01_vw_general_order_performance.sql
-- Vista general de rendimiento logístico
-- ============================================================
-- Objetivo:
-- Crear una vista reutilizable con los principales indicadores
-- generales de rendimiento logístico.
--
-- Uso:
-- Esta vista puede conectarse directamente a Power BI para crear
-- tarjetas KPI generales del dashboard.
--
-- Vista creada:
-- analytics.vw_general_order_performance
--
-- Tabla principal:
-- analytics.fact_orders
-- ============================================================

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
-- Comprobación de la vista creada
-- ============================================================

SELECT *
FROM analytics.vw_general_order_performance;