    WITH customer_orders AS (
        SELECT
            c.customer_unique_id,
            o.order_id,
            DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
        FROM olist_orders_dataset o
        JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
        WHERE o.order_status NOT IN ('canceled', 'unavailable')
    ),
    first_purchase AS (
        SELECT
            customer_unique_id,
            MIN(order_month) AS cohort_month
        FROM customer_orders
        GROUP BY 1
    ),
    cohort_activity AS (
        SELECT
            f.cohort_month,
            co.order_month,
            DATEDIFF('month', f.cohort_month, co.order_month) AS month_number,
            COUNT(DISTINCT co.customer_unique_id) AS active_customers
        FROM customer_orders co
        JOIN first_purchase f ON co.customer_unique_id = f.customer_unique_id
        GROUP BY 1, 2, 3
    ),
    cohort_size AS (
        SELECT cohort_month, COUNT(*) AS num_customers
        FROM first_purchase
        GROUP BY 1
    )
    SELECT
        ca.cohort_month,
        ca.month_number,
        ca.active_customers,
        cs.num_customers AS cohort_size,
        ROUND(ca.active_customers * 100.0 / cs.num_customers, 2) AS retention_pct
    FROM cohort_activity ca
    JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
    ORDER BY ca.cohort_month, ca.month_number