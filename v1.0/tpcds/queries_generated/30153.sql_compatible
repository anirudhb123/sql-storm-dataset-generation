
WITH RECURSIVE sales_cte AS (
    SELECT ss_sold_date_sk, 
           ss_item_sk, 
           SUM(ss_sales_price) AS total_sales,
           RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY ss_sold_date_sk, ss_item_sk
    UNION ALL
    SELECT ss.sold_date_sk, 
           ss.item_sk, 
           ss.total_sales + cte.total_sales AS total_sales,
           RANK() OVER (PARTITION BY ss.item_sk ORDER BY (ss.total_sales + cte.total_sales) DESC) AS sales_rank
    FROM sales_cte cte
    JOIN store_sales ss ON cte.ss_item_sk = ss.ss_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 20210101 AND 20230101
),
customer_summary AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
           SUM(ss.ss_net_paid) AS total_spent,
           AVG(ss.ss_net_paid) AS avg_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
best_customers AS (
    SELECT cs.*, 
           ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_summary cs
    WHERE cs.purchase_count > 5
),
date_analysis AS (
    SELECT dd.d_year,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY dd.d_year
),
reason_analysis AS (
    SELECT r.r_reason_desc,
           SUM(cr.cr_return_quantity) AS total_returns,
           SUM(cr.cr_return_amt) AS total_return_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_spent,
    cs.purchase_count,
    ba.total_orders,
    ba.total_profit,
    ra.r_reason_desc,
    ra.total_returns,
    ra.total_return_amount
FROM customer c
JOIN best_customers cs ON c.c_customer_sk = cs.c_customer_sk
JOIN date_analysis ba ON ba.total_orders > 100
JOIN reason_analysis ra ON ra.total_returns > 0
WHERE cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC, ba.total_profit DESC
LIMIT 10;
