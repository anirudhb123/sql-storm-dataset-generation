
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year, 1 AS level
    FROM customer
    WHERE c_birth_year IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
), 
recent_sales AS (
    SELECT ws.bill_customer_sk, SUM(ws.net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.bill_customer_sk
), 
customer_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_birth_year,
        COALESCE(rs.total_sales, 0) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(rs.total_sales, 0) DESC) AS sales_rank
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN recent_sales rs ON c.c_customer_sk = rs.bill_customer_sk
), 
top_customers AS (
    SELECT *,
           CASE 
               WHEN total_sales > 1000 THEN 'High Value'
               WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_type
    FROM customer_summary
    WHERE sales_rank <= 5
    ORDER BY ca_city, total_sales DESC
)
SELECT 
    tc.ca_city,
    STRING_AGG(CONCAT(tc.c_first_name, ' ', tc.c_last_name, ' (', tc.customer_type, ')'), ', ') AS top_customers
FROM top_customers tc
GROUP BY tc.ca_city
ORDER BY tc.ca_city;
