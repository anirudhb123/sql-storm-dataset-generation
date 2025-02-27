
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk
    HAVING SUM(ws_net_profit) > 1000
    UNION ALL
    SELECT 
        t.ws_sold_date_sk,
        t.total_sales + s.total_sales AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY t.ws_sold_date_sk ORDER BY t.total_sales DESC) AS sales_rank
    FROM sales_trends t
    JOIN web_sales s ON t.ws_sold_date_sk = s.ws_sold_date_sk
    WHERE t.sales_rank < 3
),
customer_performance AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ss_net_profit), 0) AS total_store_sales,
        COALESCE(SUM(ws_net_profit), 0) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        COUNT(DISTINCT ss_ticket_number) AS store_orders
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cp.total_store_sales,
        cp.total_web_sales,
        CASE 
            WHEN cp.total_store_sales + cp.total_web_sales > 5000 THEN 'High Value'
            ELSE 'Standard'
        END as customer_segment
    FROM customer_performance cp
    JOIN customer c ON cp.c_customer_id = c.c_customer_id
)
SELECT 
    hvc.customer_segment,
    COUNT(hvc.c_customer_id) AS customer_count,
    AVG(hvc.total_store_sales) AS avg_store_sales,
    AVG(hvc.total_web_sales) AS avg_web_sales,
    SUM(COALESCE(hvc.total_store_sales, 0) + COALESCE(hvc.total_web_sales, 0)) AS total_sales,
    (SELECT COUNT(DISTINCT sm.ship_mode_sk) FROM ship_mode sm) AS total_ship_modes
FROM high_value_customers hvc
GROUP BY hvc.customer_segment
ORDER BY total_sales DESC;
