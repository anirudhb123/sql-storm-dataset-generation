
WITH RECURSIVE customer_totals AS (
    SELECT c.c_customer_sk,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(ws.ws_net_profit) > 1000
    UNION ALL
    SELECT ct.c_customer_sk,
           ct.total_net_profit
    FROM customer_totals ct
    JOIN store_sales ss ON ct.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_net_paid > 500
),
ranked_customers AS (
    SELECT c.c_customer_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_birth_year ORDER BY ct.total_net_profit DESC) AS rank
    FROM customer c
    JOIN customer_totals ct ON c.c_customer_sk = ct.c_customer_sk
),
sales_data AS (
    SELECT d.d_year,
           SUM(ws.ws_net_profit) AS total_sales,
           SUM(ss.ss_net_profit) AS total_store_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_year
)
SELECT r.rank,
       COALESCE(sd.total_sales, 0) AS online_sales,
       COALESCE(sd.total_store_sales, 0) AS store_sales,
       CASE
           WHEN r.rank <= 10 THEN 'Top Customer'
           ELSE 'Regular Customer'
       END AS customer_status
FROM ranked_customers r
LEFT JOIN sales_data sd ON r.c_customer_sk = sd.d_year
WHERE r.rank IS NOT NULL
ORDER BY r.rank;
