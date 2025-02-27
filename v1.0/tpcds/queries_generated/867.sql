
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_profit + cs.total_store_profit AS combined_profit,
        RANK() OVER (ORDER BY cs.total_web_profit DESC, cs.total_store_profit DESC) AS profit_rank
    FROM customer_sales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.combined_profit,
    CASE 
        WHEN tc.combined_profit IS NULL THEN 'No Profit Recorded'
        ELSE 'Profit Recorded'
    END AS profit_status,
    (SELECT COUNT(DISTINCT ws.web_site_sk)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk
    ) AS distinct_websites_used
FROM top_customers tc
WHERE profit_rank <= 10
ORDER BY tc.combined_profit DESC;
