
WITH sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           c.c_birth_year, d.d_year, 
           ws.ws_net_profit AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    UNION ALL
    SELECT sh.c_customer_sk, sh.c_customer_id, sh.c_first_name, sh.c_last_name, 
           sh.c_birth_year, sh.d_year, 
           ws.ws_net_profit AS total_profit
    FROM sales_hierarchy sh
    JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = sh.d_year + 1
),
monthly_sales AS (
    SELECT d.d_year, d.d_month_seq, 
           SUM(ws.ws_net_profit) AS monthly_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY d.d_year, d.d_month_seq
),
top_profit_customers AS (
    SELECT customer.c_customer_sk, customer.c_customer_id, customer.c_first_name, 
           customer.c_last_name, COALESCE(SUM(monthly_sales.monthly_profit), 0) AS total_monthly_profit
    FROM customer
    LEFT JOIN monthly_sales ON monthly_sales.d_year = customer.c_birth_year % 2020 
    GROUP BY customer.c_customer_sk, customer.c_customer_id, customer.c_first_name, customer.c_last_name
),
overall_stats AS (
    SELECT 
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(total_monthly_profit) AS avg_profit_per_customer,
        SUM(total_monthly_profit) AS total_profits
    FROM top_profit_customers c
)
SELECT 
    o.total_customers,
    o.avg_profit_per_customer,
    o.total_profits,
    RANK() OVER (ORDER BY o.total_profits DESC) AS profit_rank
FROM overall_stats o
WHERE o.avg_profit_per_customer IS NOT NULL 
ORDER BY profit_rank
LIMIT 10;
