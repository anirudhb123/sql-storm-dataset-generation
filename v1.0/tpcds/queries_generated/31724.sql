
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, 
           0 AS level
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
           sh.level + 1
    FROM customer c
    INNER JOIN sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
),
customer_sales AS (
    SELECT c.c_customer_sk,
           SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) AS total_sales,
           d.d_year
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk IN (ws.ws_sold_date_sk, cs.cs_sold_date_sk)
    GROUP BY c.c_customer_sk, d.d_year
),
sales_analysis AS (
    SELECT c.c_customer_sk, s.total_sales,
           DENSE_RANK() OVER (ORDER BY s.total_sales DESC) as sales_rank,
           COALESCE(d.d_year, 0) as year
    FROM customer_sales s
    JOIN customer c ON s.c_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON d.d_year = s.year
)
SELECT sa.c_customer_sk, 
       sa.total_sales, 
       sa.sales_rank, 
       ca.ca_city, 
       ca.ca_state,
       CASE
           WHEN sa.total_sales > 10000 THEN 'High Value'
           WHEN sa.total_sales > 5000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       CASE 
           WHEN (SELECT COUNT(*) FROM customer_address ca WHERE ca.ca_state = 'CA') > 1000 THEN 'California Has High Customers'
           ELSE 'California Customers Below Threshold'
       END AS ca_popularity,
       COUNT(DISTINCT sh.c_customer_sk) OVER () AS total_preferred_customers
FROM sales_analysis sa
JOIN customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = sa.c_customer_sk)
LEFT JOIN sales_hierarchy sh ON sh.c_customer_sk = sa.c_customer_sk
WHERE (ca.ca_state IS NOT NULL AND ca.ca_state <> '')
ORDER BY sa.sales_rank
LIMIT 100;
