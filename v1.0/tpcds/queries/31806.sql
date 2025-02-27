
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk AS customer_sk, c.c_first_name || ' ' || c.c_last_name AS customer_name, 
           cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, 
           cd.cd_dep_count, cd.cd_dep_employed_count, cd.cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name || ' ' || c.c_last_name, 
           cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, cd.cd_dep_count, cd.cd_dep_employed_count, cd.cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_hierarchy ch ON ch.customer_sk = c.c_customer_sk
    WHERE cd.cd_purchase_estimate > ch.cd_purchase_estimate
),
total_sales AS (
    SELECT ws_bill_customer_sk AS customer_sk, SUM(ws_net_paid) AS total_spent
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
recent_activity AS (
    SELECT ws_bill_customer_sk AS customer_sk, COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY ws_bill_customer_sk
),
combined_sales AS (
    SELECT c.customer_sk, c.customer_name, 
           COALESCE(ts.total_spent, 0) AS total_spent,
           COALESCE(ra.order_count, 0) AS order_count,
           c.cd_gender, c.cd_marital_status
    FROM customer_hierarchy c
    LEFT JOIN total_sales ts ON c.customer_sk = ts.customer_sk
    LEFT JOIN recent_activity ra ON c.customer_sk = ra.customer_sk
)
SELECT customer_name, total_spent, order_count, cd_gender, cd_marital_status
FROM combined_sales
WHERE total_spent > (SELECT AVG(total_spent) FROM total_sales)
ORDER BY total_spent DESC
LIMIT 10;
