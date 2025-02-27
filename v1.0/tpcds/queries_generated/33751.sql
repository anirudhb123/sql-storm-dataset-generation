
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           cd.cd_dep_count,
           cd.cd_dep_employed_count,
           cd.cd_dep_college_count,
           1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
    UNION ALL
    SELECT s.c_customer_sk,
           CONCAT(s.c_first_name, ' ', s.c_last_name) AS full_name,
           sd.cd_gender,
           sd.cd_marital_status,
           sd.cd_purchase_estimate,
           sd.cd_credit_rating,
           sd.cd_dep_count,
           sd.cd_dep_employed_count,
           sd.cd_dep_college_count,
           h.level + 1
    FROM customer s
    JOIN customer_demographics sd ON s.c_current_cdemo_sk = sd.cd_demo_sk
    JOIN sales_hierarchy h ON h.c_customer_sk = s.c_current_hdemo_sk
    WHERE sd.cd_purchase_estimate IS NOT NULL
),
date_analysis AS (
    SELECT dd.d_year,
           dd.d_month_seq,
           SUM(ws.ws_net_profit) AS total_profit
    FROM date_dim dd
    JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE dd.d_year >= 2020
    GROUP BY dd.d_year, dd.d_month_seq
),
customer_sales AS (
    SELECT h.full_name,
           COALESCE(sum(ws.ws_net_profit), 0) AS total_sales_profit,
           COUNT(DISTINCT ws.ws_order_number) AS orders_count,
           RANK() OVER (PARTITION BY h.cd_gender ORDER BY COALESCE(sum(ws.ws_net_profit), 0) DESC) AS sales_rank
    FROM sales_hierarchy h
    LEFT JOIN web_sales ws ON h.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY h.full_name
)
SELECT c.full_name,
       cd.cd_gender,
       cd.cd_marital_status,
       cs.total_sales_profit,
       da.total_profit AS monthly_profit,
       CASE
           WHEN cs.orders_count > 10 THEN 'High Value'
           WHEN cs.orders_count BETWEEN 5 AND 10 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value_level
FROM customer_sales cs
JOIN customer_demographics cd ON cs.full_name = CONCAT(cd.cd_gender, ' ', cd.cd_marital_status)
JOIN date_analysis da ON (da.d_month_seq BETWEEN 1 AND 12)
WHERE cs.sales_rank <= 5
ORDER BY cs.total_sales_profit DESC, cd.cd_gender;
