-- ============================================================
-- 04_delay_by_order_value.sql
-- Retrasos según el valor económico del pedido
-- ============================================================
-- Objetivo:
-- Este script analiza si el valor económico del pedido se relaciona
-- con la probabilidad de retraso logístico.
--
-- Para ello se estudian tres variables:
-- - total_items_value: valor total de los productos del pedido.
-- - total_payment_value: valor total pagado por el cliente.
-- - total_freight_value: coste total de envío asociado al pedido.
--
-- Tabla principal:
-- analytics.fact_orders
--
-- Notas:
-- - Solo se consideran pedidos con order_status = 'delivered'.
-- - is_delayed = true indica que el pedido fue entregado con retraso.
-- - Se calculan dos tipos de porcentajes:
--   1. Porcentaje del tramo económico sobre el total de pedidos retrasados.
--   2. Porcentaje de retraso dentro del propio tramo económico.
-- - Se utiliza NULLIF para evitar divisiones entre cero.
-- - Se utiliza ::numeric para poder aplicar ROUND con dos decimales.
-- ============================================================


-- ============================================================
-- 1. Retrasos según valor de productos
-- ============================================================
-- Variable analizada:
-- total_items_value
--
-- Interpretación:
-- Permite analizar si los pedidos con productos de mayor valor
-- presentan una mayor o menor probabilidad de retraso.
--
-- porcentaje_valor_X_sobre_total_retrasados:
-- De todos los pedidos retrasados, qué porcentaje pertenece a ese
-- tramo de valor de productos.
--
-- porcentaje_retraso_dentro_valor_X:
-- De todos los pedidos de ese tramo de valor de productos, qué
-- porcentaje se retrasó.
-- ============================================================

SELECT 
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
    ) AS total_pedidos_retrasados,


    -- ========================================================
    -- Pedidos con valor entre 0 y 50
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_items_value > 0
          AND total_items_value <= 50
    ) AS total_pedidos_valor_0a50,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_items_value > 0
          AND total_items_value <= 50
    ) AS pedidos_retrasados_valor_0a50,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 0
              AND total_items_value <= 50
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_valor_0a50_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 0
              AND total_items_value <= 50
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_items_value > 0
                  AND total_items_value <= 50
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_valor_0a50,


    -- ========================================================
    -- Pedidos con valor entre 50 y 100
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_items_value > 50
          AND total_items_value <= 100
    ) AS total_pedidos_valor_50a100,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_items_value > 50
          AND total_items_value <= 100
    ) AS pedidos_retrasados_valor_50a100,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 50
              AND total_items_value <= 100
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_valor_50a100_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 50
              AND total_items_value <= 100
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_items_value > 50
                  AND total_items_value <= 100
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_valor_50a100,


    -- ========================================================
    -- Pedidos con valor entre 100 y 250
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_items_value > 100
          AND total_items_value <= 250
    ) AS total_pedidos_valor_100a250,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_items_value > 100
          AND total_items_value <= 250
    ) AS pedidos_retrasados_valor_100a250,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 100
              AND total_items_value <= 250
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_valor_100a250_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 100
              AND total_items_value <= 250
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_items_value > 100
                  AND total_items_value <= 250
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_valor_100a250,


    -- ========================================================
    -- Pedidos con valor entre 250 y 500
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_items_value > 250
          AND total_items_value <= 500
    ) AS total_pedidos_valor_250a500,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_items_value > 250
          AND total_items_value <= 500
    ) AS pedidos_retrasados_valor_250a500,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 250
              AND total_items_value <= 500
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_valor_250a500_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 250
              AND total_items_value <= 500
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_items_value > 250
                  AND total_items_value <= 500
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_valor_250a500,


    -- ========================================================
    -- Pedidos con valor superior a 500
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_items_value > 500
    ) AS total_pedidos_valor_mas_de_500,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_items_value > 500
    ) AS pedidos_retrasados_valor_mas_de_500,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 500
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_valor_mas_de_500_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_items_value > 500
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_items_value > 500
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_valor_mas_de_500

FROM analytics.fact_orders;


-- ============================================================
-- 2. Retrasos según valor total pagado
-- ============================================================
-- Variable analizada:
-- total_payment_value
--
-- Interpretación:
-- Permite analizar si los pedidos de mayor importe total pagado
-- presentan una mayor o menor probabilidad de retraso.
--
-- A diferencia de total_items_value, esta variable representa el
-- valor total pagado por el cliente.
--
-- porcentaje_pago_X_sobre_total_retrasados:
-- De todos los pedidos retrasados, qué porcentaje pertenece a ese
-- tramo de valor pagado.
--
-- porcentaje_retraso_dentro_pago_X:
-- De todos los pedidos de ese tramo de valor pagado, qué porcentaje
-- se retrasó.
-- ============================================================

SELECT 
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
    ) AS total_pedidos_retrasados,


    -- ========================================================
    -- Pedidos con valor pagado entre 0 y 50
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_payment_value > 0
          AND total_payment_value <= 50
    ) AS total_pedidos_pago_0a50,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_payment_value > 0
          AND total_payment_value <= 50
    ) AS pedidos_retrasados_pago_0a50,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 0
              AND total_payment_value <= 50
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_pago_0a50_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 0
              AND total_payment_value <= 50
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_payment_value > 0
                  AND total_payment_value <= 50
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_pago_0a50,


    -- ========================================================
    -- Pedidos con valor pagado entre 50 y 100
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_payment_value > 50
          AND total_payment_value <= 100
    ) AS total_pedidos_pago_50a100,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_payment_value > 50
          AND total_payment_value <= 100
    ) AS pedidos_retrasados_pago_50a100,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 50
              AND total_payment_value <= 100
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_pago_50a100_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 50
              AND total_payment_value <= 100
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_payment_value > 50
                  AND total_payment_value <= 100
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_pago_50a100,


    -- ========================================================
    -- Pedidos con valor pagado entre 100 y 250
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_payment_value > 100
          AND total_payment_value <= 250
    ) AS total_pedidos_pago_100a250,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_payment_value > 100
          AND total_payment_value <= 250
    ) AS pedidos_retrasados_pago_100a250,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 100
              AND total_payment_value <= 250
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_pago_100a250_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 100
              AND total_payment_value <= 250
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_payment_value > 100
                  AND total_payment_value <= 250
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_pago_100a250,


    -- ========================================================
    -- Pedidos con valor pagado entre 250 y 500
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_payment_value > 250
          AND total_payment_value <= 500
    ) AS total_pedidos_pago_250a500,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_payment_value > 250
          AND total_payment_value <= 500
    ) AS pedidos_retrasados_pago_250a500,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 250
              AND total_payment_value <= 500
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_pago_250a500_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 250
              AND total_payment_value <= 500
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_payment_value > 250
                  AND total_payment_value <= 500
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_pago_250a500,


    -- ========================================================
    -- Pedidos con valor pagado superior a 500
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_payment_value > 500
    ) AS total_pedidos_pago_mas_de_500,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_payment_value > 500
    ) AS pedidos_retrasados_pago_mas_de_500,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 500
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_pago_mas_de_500_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_payment_value > 500
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_payment_value > 500
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_pago_mas_de_500

FROM analytics.fact_orders;


-- ============================================================
-- 3. Retrasos según coste de envío
-- ============================================================
-- Variable analizada:
-- total_freight_value
--
-- Interpretación:
-- Permite analizar si los pedidos con mayor coste de envío presentan
-- una mayor o menor probabilidad de retraso.
--
-- porcentaje_envio_X_sobre_total_retrasados:
-- De todos los pedidos retrasados, qué porcentaje pertenece a ese
-- tramo de coste de envío.
--
-- porcentaje_retraso_dentro_envio_X:
-- De todos los pedidos de ese tramo de coste de envío, qué porcentaje
-- se retrasó.
-- ============================================================

SELECT 
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
    ) AS total_pedidos_retrasados,


    -- ========================================================
    -- Pedidos con coste de envío entre 0 y 10
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_freight_value > 0
          AND total_freight_value <= 10
    ) AS total_pedidos_envio_0a10,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_freight_value > 0
          AND total_freight_value <= 10
    ) AS pedidos_retrasados_envio_0a10,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 0
              AND total_freight_value <= 10
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_envio_0a10_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 0
              AND total_freight_value <= 10
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_freight_value > 0
                  AND total_freight_value <= 10
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_envio_0a10,


    -- ========================================================
    -- Pedidos con coste de envío entre 10 y 20
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_freight_value > 10
          AND total_freight_value <= 20
    ) AS total_pedidos_envio_10a20,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_freight_value > 10
          AND total_freight_value <= 20
    ) AS pedidos_retrasados_envio_10a20,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 10
              AND total_freight_value <= 20
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_envio_10a20_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 10
              AND total_freight_value <= 20
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_freight_value > 10
                  AND total_freight_value <= 20
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_envio_10a20,


    -- ========================================================
    -- Pedidos con coste de envío entre 20 y 40
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_freight_value > 20
          AND total_freight_value <= 40
    ) AS total_pedidos_envio_20a40,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_freight_value > 20
          AND total_freight_value <= 40
    ) AS pedidos_retrasados_envio_20a40,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 20
              AND total_freight_value <= 40
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_envio_20a40_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 20
              AND total_freight_value <= 40
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_freight_value > 20
                  AND total_freight_value <= 40
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_envio_20a40,


    -- ========================================================
    -- Pedidos con coste de envío entre 40 y 80
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_freight_value > 40
          AND total_freight_value <= 80
    ) AS total_pedidos_envio_40a80,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_freight_value > 40
          AND total_freight_value <= 80
    ) AS pedidos_retrasados_envio_40a80,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 40
              AND total_freight_value <= 80
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_envio_40a80_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 40
              AND total_freight_value <= 80
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_freight_value > 40
                  AND total_freight_value <= 80
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_envio_40a80,


    -- ========================================================
    -- Pedidos con coste de envío superior a 80
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND total_freight_value > 80
    ) AS total_pedidos_envio_mas_de_80,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND is_delayed = true
          AND total_freight_value > 80
    ) AS pedidos_retrasados_envio_mas_de_80,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 80
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND is_delayed = true
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_envio_mas_de_80_sobre_total_retrasados,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND is_delayed = true
              AND total_freight_value > 80
        )::numeric
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND total_freight_value > 80
            ),
            0
        ) * 100,
        2
    ) AS porcentaje_retraso_dentro_envio_mas_de_80

FROM analytics.fact_orders;