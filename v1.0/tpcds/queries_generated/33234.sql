
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        0 AS level
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    UNION ALL
    SELECT 
        s.c_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        sh.level + 1
    FROM customer s
    JOIN web_sales ws ON s.c_customer_sk = ws.ws_bill_customer_sk
    JOIN sales_hierarchy sh ON s.c_current_hdemo_sk = sh.customer_id
    GROUP BY s.c_customer_sk, sh.level
),
profit_analysis AS (
    SELECT 
        s.c_customer_id,
        s.c_first_name,
        s.c_last_name,
        sh.total_profit,
        sh.total_orders,
        ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY sh.total_profit DESC) AS rank_within_level
    FROM customer s
    JOIN sales_hierarchy sh ON s.c_customer_sk = sh.customer_id
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(pa.total_profit, 0) AS profit,
    COALESCE(pa.total_orders, 0) AS orders,
    CASE 
        WHEN pa.rank_within_level <= 10 THEN 'Top Performer'
        WHEN pa.rank_within_level <= 50 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM customer c
LEFT JOIN profit_analysis pa ON c.c_customer_id = pa.c_customer_id
ORDER BY c.c_last_name ASC, c.c_first_name ASC;
