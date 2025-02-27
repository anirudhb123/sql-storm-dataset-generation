
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ss_store_sk
),
customer_return AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COALESCE(cr.total_returns, 0) AS return_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN customer_return cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING total_spent > 1000 AND return_count < 5
),
combined_sales AS (
    SELECT 
        wh.w_warehouse_id,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN warehouse wh ON ss.ss_store_sk = wh.w_warehouse_sk
    GROUP BY wh.w_warehouse_id, ss.ss_sold_date_sk
),
final_rating AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.return_count,
        COALESCE(s.total_sales, 0) AS total_sales,
        CASE 
            WHEN cs.return_count > 0 THEN 'At Risk'
            WHEN cs.total_spent < 2000 THEN 'Low Value'
            ELSE 'High Value'
        END AS customer_value
    FROM top_customers cs
    LEFT JOIN combined_sales s ON cs.c_customer_sk = s.ss_sold_date_sk
)
SELECT 
    customer_value,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spent,
    SUM(return_count) AS total_returns,
    SUM(total_sales) AS total_sales_amount
FROM final_rating
GROUP BY customer_value
ORDER BY customer_value DESC;
