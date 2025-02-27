
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS sales_count
    FROM customer_sales cs
    LEFT JOIN web_sales ws ON cs.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
        SUM(cs.total_sales) AS total_promo_sales
    FROM promotion p
    JOIN store_sales ss ON p.p_promo_sk = ss.ss_promo_sk
    JOIN customer_sales cs ON ss.ss_customer_sk = cs.c_customer_sk
    GROUP BY p.p_promo_id
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_net_profit) AS total_warehouse_sales
    FROM warehouse w
    JOIN store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY w.w_warehouse_id
),
top_warehouses AS (
    SELECT 
        w.warehouse_id,
        total_warehouse_sales,
        RANK() OVER (ORDER BY total_warehouse_sales DESC) AS warehouse_rank
    FROM warehouse_summary w
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales AS customer_total_sales,
    ps.unique_customers AS promo_unique_customers,
    ps.total_promo_sales AS promo_sales,
    tw.warehouse_id AS top_warehouse_id,
    tw.total_warehouse_sales AS top_warehouse_sales
FROM customer_sales cs
LEFT JOIN promotion_summary ps ON cs.total_sales > 1000
LEFT JOIN top_warehouses tw ON cs.c_customer_sk = tw.warehouse_id
WHERE cs.total_sales IS NOT NULL
ORDER BY customer_total_sales DESC;
