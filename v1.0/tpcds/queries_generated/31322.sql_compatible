
WITH RECURSIVE sales_data AS (
    SELECT ws.web_site_sk,
           SUM(ws.ws_net_paid_inc_tax) AS total_sales,
           DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk
),
top_sales AS (
    SELECT web_site_sk, total_sales
    FROM sales_data
    WHERE sales_rank <= 10
),
customer_info AS (
    SELECT c.c_customer_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           ca.ca_city,
           COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city
),
aggregate_info AS (
    SELECT ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_education_status,
           ci.ca_city,
           SUM(CASE WHEN ci.total_orders > 10 THEN 1 ELSE 0 END) AS high_order_customers,
           AVG(ci.total_orders) AS avg_orders
    FROM customer_info ci
    JOIN top_sales ts ON ci.c_customer_sk = ts.web_site_sk
    GROUP BY ci.cd_gender, ci.cd_marital_status, ci.cd_education_status, ci.ca_city
)
SELECT ai.cd_gender,
       ai.cd_marital_status,
       ai.cd_education_status,
       ai.ca_city,
       ai.high_order_customers,
       ai.avg_orders,
       COUNT(DISTINCT ai.cd_gender) OVER (PARTITION BY ai.ca_city) AS city_gender_count
FROM aggregate_info ai
WHERE ai.high_order_customers > 0
ORDER BY ai.ca_city, ai.avg_orders DESC;
