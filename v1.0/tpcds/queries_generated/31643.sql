
WITH RECURSIVE date_hierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT d.date_sk, d.d_date, d.d_year, d.d_month_seq
    FROM date_dim d
    INNER JOIN date_hierarchy dh ON d.d_month_seq = dh.d_month_seq - 1
    WHERE d.d_year = dh.d_year
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           cd.cd_purchase_estimate, ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_profit DESC) as profit_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
),
returns_data AS (
    SELECT sr.store_sk, SUM(sr.return_quantity) AS total_returns,
           COUNT(DISTINCT sr.ticket_number) AS return_count
    FROM store_returns sr
    GROUP BY sr.store_sk
)
SELECT d.d_year, COUNT(DISTINCT ci.c_customer_sk) AS total_customers,
       SUM(sd.ws_quantity) AS total_sales_quantity,
       SUM(CASE WHEN rd.total_returns IS NOT NULL THEN rd.total_returns ELSE 0 END) AS total_returns,
       AVG(sd.ws_net_profit) AS average_profit,
       MAX(CASE WHEN ci.rn = 1 THEN ci.c_first_name || ' ' || ci.c_last_name END) AS high_value_customer
FROM date_hierarchy d
LEFT JOIN customer_info ci ON ci.rn <= 10
LEFT JOIN sales_data sd ON sd.ws_sold_date_sk = d.d_date_sk
LEFT JOIN returns_data rd ON rd.store_sk = sd.ws_item_sk
WHERE d.d_month_seq IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2023)
GROUP BY d.d_year
ORDER BY d.d_year DESC;
