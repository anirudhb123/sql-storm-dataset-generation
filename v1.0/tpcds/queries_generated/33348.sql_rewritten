WITH RECURSIVE date_hierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_quarter_seq, d_dow, 1 AS is_weekend
    FROM date_dim
    WHERE d_date = '2001-10-01'
    
    UNION ALL
    
    SELECT dd.d_date_sk, dd.d_date, dd.d_year, dd.d_month_seq, dd.d_quarter_seq, dd.d_dow,
           CASE WHEN dd.d_weekend = '1' THEN 1 ELSE is_weekend + 1 END
    FROM date_dim dd
    JOIN date_hierarchy dh ON dd.d_date_sk = dh.d_date_sk + 1
    WHERE is_weekend < 2
),
sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS order_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_hierarchy)
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT c.c_customer_id, cs.total_profit, cs.total_orders,
           CASE 
               WHEN cs.total_orders >= 10 THEN 'Frequent'
               WHEN cs.total_profit >= 1000 THEN 'High Value'
               ELSE 'Occasional'
           END AS customer_type
    FROM sales_summary cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.order_rank <= 100
)
SELECT 
    tc.customer_type,
    COUNT(tc.c_customer_id) AS customer_count,
    AVG(tc.total_profit) AS avg_profit,
    SUM(tc.total_orders) AS total_orders_summary 
FROM top_customers tc
GROUP BY tc.customer_type
ORDER BY avg_profit DESC
LIMIT 5;