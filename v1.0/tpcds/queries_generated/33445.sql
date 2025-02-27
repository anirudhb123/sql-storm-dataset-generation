
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           c_current_addr_sk, 
           c_current_cdemo_sk, 
           1 AS level
    FROM customer 
    WHERE c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           c.c_current_addr_sk, 
           c.c_current_cdemo_sk, 
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
),
sales_data AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           AVG(ws_net_paid) AS avg_order_value
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) 
                                   FROM date_dim 
                                   WHERE d_year = 2021) 
                            AND (SELECT MAX(d_date_sk) 
                                  FROM date_dim 
                                  WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
customer_sales AS (
    SELECT ch.c_customer_sk, 
           ch.c_first_name, 
           ch.c_last_name, 
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(sd.order_count, 0) AS order_count,
           COALESCE(sd.avg_order_value, 0) AS avg_order_value
    FROM customer_hierarchy ch
    LEFT JOIN sales_data sd ON ch.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT c.c_first_name, 
       c.c_last_name, 
       CASE 
           WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Spender'
           WHEN cs.total_sales > 5000 THEN 'High Spender'
           ELSE 'Low Spender'
       END AS spending_category,
       c.c_current_addr_sk,
       ROW_NUMBER() OVER (PARTITION BY spending_category ORDER BY cs.total_sales DESC) AS rank
FROM customer_sales cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE c.c_birth_year IS NOT NULL 
      AND c.c_birth_month IS NOT NULL
ORDER BY spending_category, total_sales DESC;
