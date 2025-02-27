
WITH RECURSIVE date_hierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, d_dow
    FROM date_dim
    WHERE d_year = 2023
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq, d.d_dow
    FROM date_dim d
    JOIN date_hierarchy dh ON d.d_date_sk = dh.d_date_sk + 1
    WHERE d.d_year = 2023
),
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT ws.ws_sold_date_sk, 
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY ws.ws_sold_date_sk
),
revenue_by_month AS (
    SELECT dh.d_month_seq, 
           SUM(ss.total_profit) AS monthly_profit, 
           SUM(ss.total_orders) AS monthly_orders
    FROM sales_summary ss
    JOIN date_hierarchy dh ON ss.ws_sold_date_sk = dh.d_date_sk
    GROUP BY dh.d_month_seq
)
SELECT 
    dh.d_year,
    dh.d_month_seq,
    COALESCE(rbm.monthly_profit, 0) AS monthly_profit,
    COALESCE(rbm.monthly_orders, 0) AS total_orders,
    AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(ci.cd_purchase_estimate) AS max_purchase_estimate,
    MIN(ci.cd_purchase_estimate) AS min_purchase_estimate
FROM date_hierarchy dh
LEFT JOIN revenue_by_month rbm ON dh.d_month_seq = rbm.d_month_seq
JOIN customer_info ci ON ci.gender_rank = 1
WHERE dh.d_year IS NOT NULL
GROUP BY dh.d_year, dh.d_month_seq, rbm.monthly_profit, rbm.monthly_orders
ORDER BY dh.d_year, dh.d_month_seq;
