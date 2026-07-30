-- ============================================================
-- 01_general_delivery_kpis.sql
-- General logistics performance KPIs
-- ============================================================
-- Purpose:
-- This script calculates the main general indicators used to
-- evaluate logistics performance in the Olist marketplace.
--
-- Main table:
-- analytics.fact_orders
--
-- Notes:
-- - Delay-related KPIs are calculated only for delivered orders.
-- - approval_time_days is converted to hours for better readability.
-- - delivery and delay times are kept in days.
-- ============================================================


-- ============================================================
-- 1. Total number of orders
-- ============================================================

SELECT 
    COUNT(*) AS total_orders
FROM analytics.fact_orders;


-- ============================================================
-- 2. Total number of delivered orders
-- ============================================================

SELECT 
    COUNT(*) AS delivered_orders
FROM analytics.fact_orders
WHERE order_status = 'delivered';


-- ============================================================
-- 3. Total number of delayed delivered orders
-- ============================================================

SELECT 
    COUNT(*) AS delayed_orders
FROM analytics.fact_orders
WHERE order_status = 'delivered'
  AND is_delayed = true;


-- ============================================================
-- 4. Percentage of delayed orders over delivered orders
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
-- 5. Average approval time
-- ============================================================
-- The value is stored in days in fact_orders.
-- It is converted to hours to improve readability.

SELECT
    ROUND(
        AVG(approval_time_days * 24),
        2
    ) AS avg_approval_time_hours
FROM analytics.fact_orders
WHERE approval_time_days IS NOT NULL;


-- ============================================================
-- 6. Average total delivery time
-- ============================================================
-- Calculated only for delivered orders.

SELECT
    ROUND(
        AVG(total_delivery_time_days),
        2
    ) AS avg_total_delivery_time_days
FROM analytics.fact_orders
WHERE order_status = 'delivered'
  AND total_delivery_time_days IS NOT NULL;


-- ============================================================
-- 7. Average delay days
-- ============================================================
-- Calculated only for delivered orders that were delayed.

SELECT
    ROUND(
        AVG(delay_days),
        2
    ) AS avg_delay_days
FROM analytics.fact_orders
WHERE order_status = 'delivered'
  AND is_delayed = true
  AND delay_days IS NOT NULL;


-- ============================================================
-- 8. Percentage of orders delivered before estimated date
-- ============================================================
-- delay_days < 0 means the order was delivered before the
-- estimated delivery date.

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
-- 9. Percentage of orders delivered within the expected deadline
-- ============================================================
-- delay_days <= 0 means the order was delivered on time or early.

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
-- 10. General logistics KPI summary
-- ============================================================
-- This query combines the main indicators in a single output.
-- It can be used as the basis for a KPI card in Power BI.

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
        ),
        2
    ) AS avg_approval_time_hours,

    ROUND(
        AVG(total_delivery_time_days) FILTER (
            WHERE order_status = 'delivered'
              AND total_delivery_time_days IS NOT NULL
        ),
        2
    ) AS avg_total_delivery_time_days,

    ROUND(
        AVG(delay_days) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND delay_days IS NOT NULL
        ),
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
-- 11. Create reusable view for Power BI
-- ============================================================
-- This view stores the general logistics KPIs and can be used
-- directly as a source for Power BI cards.

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
        ),
        2
    ) AS avg_approval_time_hours,

    ROUND(
        AVG(total_delivery_time_days) FILTER (
            WHERE order_status = 'delivered'
              AND total_delivery_time_days IS NOT NULL
        ),
        2
    ) AS avg_total_delivery_time_days,

    ROUND(
        AVG(delay_days) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND delay_days IS NOT NULL
        ),
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
-- 12. Check created view
-- ============================================================

SELECT *
FROM analytics.vw_general_order_performance;