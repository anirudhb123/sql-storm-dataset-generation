
WITH RECURSIVE sales_cte AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    UNION ALL
    SELECT ss_bill_customer_sk, SUM(ss_net_profit)
    FROM store_sales
    GROUP BY ss_bill_customer_sk
),
monthly_sales AS (
    SELECT d.d_year, d.d_month_seq, SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
underperforming_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, coalesce(s.total_profit, 0) AS total_profit
    FROM customer c
    LEFT JOIN sales_cte s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE coalesce(s.total_profit, 0) < (
        SELECT AVG(total_profit)
        FROM sales_cte
    )
)
SELECT uc.c_customer_sk, uc.c_first_name, uc.c_last_name, 
       uc.total_profit, m.total_sales,
       CASE 
           WHEN m.total_sales IS NULL THEN 'No Sales'
           WHEN uc.total_profit < 100 THEN 'Low'
           WHEN uc.total_profit BETWEEN 100 AND 500 THEN 'Medium'
           ELSE 'High' 
       END AS profitability_status
FROM underperforming_customers uc
LEFT JOIN monthly_sales m ON uc.c_customer_sk = m.d_year
ORDER BY uc.total_profit DESC, m.total_sales DESC;
