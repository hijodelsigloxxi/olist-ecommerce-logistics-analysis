SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
    ) AS total_pedidos_retrasados,

    -- ========================================================
    -- Pedidos con 1 item
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items = 1
    ) AS total_pedidos_1_item,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items = 1
          AND is_delayed = true
    ) AS pedidos_retrasados_1_item,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items = 1
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_1_item_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items = 1
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND number_of_items = 1
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_1_item,


    -- ========================================================
    -- Pedidos con 2 items
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items = 2
    ) AS total_pedidos_2_items,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items = 2
          AND is_delayed = true
    ) AS pedidos_retrasados_2_items,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items = 2
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_2_items_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items = 2
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND number_of_items = 2
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_2_items,


    -- ========================================================
    -- Pedidos con 3 items
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items = 3
    ) AS total_pedidos_3_items,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items = 3
          AND is_delayed = true
    ) AS pedidos_retrasados_3_items,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items = 3
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_3_items_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items = 3
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND number_of_items = 3
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_3_items,


    -- ========================================================
    -- Pedidos con 4 items
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items = 4
    ) AS total_pedidos_4_items,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items = 4
          AND is_delayed = true
    ) AS pedidos_retrasados_4_items,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items = 4
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_4_items_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items = 4
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND number_of_items = 4
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_4_items,


    -- ========================================================
    -- Pedidos con 5 o más items
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items >= 5
    ) AS total_pedidos_5_o_mas_items,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND number_of_items >= 5
          AND is_delayed = true
    ) AS pedidos_retrasados_5_o_mas_items,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items >= 5
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_5_o_mas_items_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND number_of_items >= 5
              AND is_delayed = true
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND number_of_items >= 5
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_5_o_mas_items

FROM analytics.fact_orders;