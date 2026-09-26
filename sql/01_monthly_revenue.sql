WITH order_revenue AS (
        SELECT
            o.order_id,
            DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
            SUM(oi.price + oi.freight_value) AS order_total
        FROM olist_orders_dataset o
        JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
        WHERE o.order_status NOT IN ('canceled', 'unavailable')
        GROUP BY 1, 2
    ),
    monthly AS (
        SELECT
            order_month,
            SUM(order_total) AS revenue,
            COUNT(DISTINCT order_id) AS total_orders
        FROM order_revenue
        GROUP BY 1
    )
    SELECT
        order_month,
        revenue,
        total_orders,
        SUM(revenue) OVER (ORDER BY order_month) AS cumulative_revenue,
        LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
        ROUND(
            (revenue - LAG(revenue) OVER (ORDER BY order_month))
            / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0) * 100, 2
        ) AS mom_growth_pct
    FROM monthly
    ORDER BY order_month