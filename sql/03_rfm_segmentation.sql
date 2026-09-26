WITH customer_orders AS (
        SELECT
            c.customer_unique_id,
            o.order_id,
            o.order_purchase_timestamp,
            oi.price + oi.freight_value AS order_value
        FROM olist_orders_dataset o
        JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
        JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
        WHERE o.order_status NOT IN ('canceled', 'unavailable')
    ),
    rfm_base AS (
        SELECT
            customer_unique_id,
            DATEDIFF('day', MAX(order_purchase_timestamp), (SELECT MAX(order_purchase_timestamp) FROM customer_orders)) AS recency_days,
            COUNT(DISTINCT order_id) AS frequency,
            SUM(order_value) AS monetary
        FROM customer_orders
        GROUP BY 1
    ),
    rfm_scored AS (
        SELECT
            *,
            NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
            NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
            NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
        FROM rfm_base
    )
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customer'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customer'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
            ELSE 'Regular'
        END AS segment
    FROM rfm_scored