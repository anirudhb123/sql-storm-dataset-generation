
WITH aggregated_sales AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity, 
           SUM(ws.ws_net_paid) AS total_net_paid, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk
),
top_customers AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
    ORDER BY total_spent DESC
    LIMIT 10
),
customer_demographics AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status, 
           cd.cd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT cu.c_first_name, 
       cu.c_last_name, 
       cd.cd_gender, 
       cd.cd_marital_status, 
       SUM(as.total_net_paid) AS total_spent,
       COUNT(DISTINCT as.total_orders) AS order_count
FROM top_customers tc
JOIN customer cu ON cu.c_customer_sk = tc.ws_bill_customer_sk
JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
JOIN aggregated_sales as ON as.ws_item_sk IN (
    SELECT ws_item_sk 
    FROM web_sales 
    WHERE ws_bill_customer_sk = cu.c_customer_sk
)
GROUP BY cu.c_first_name, cu.c_last_name, cd.cd_gender, cd.cd_marital_status
HAVING SUM(as.total_net_paid) > 1000
ORDER BY total_spent DESC
LIMIT 5;
