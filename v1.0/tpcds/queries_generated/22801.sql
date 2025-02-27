
WITH RECURSIVE income_band_distribution AS (
    SELECT ib_income_band_sk,
           ib_lower_bound,
           ib_upper_bound,
           0 AS adjustment
    FROM income_band
    UNION ALL
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound + 100,
           ib.ib_upper_bound + 100,
           CASE 
               WHEN ib.ib_upper_bound IS NOT NULL AND ib.ib_upper_bound < 200 THEN adjustment + 1 
               ELSE adjustment
           END
    FROM income_band_distribution ib
    JOIN income_band ib ON ib.ib_income_band_sk = ib_income_band_sk
    WHERE ib.ib_upper_bound IS NOT NULL
), 
sales_summary AS (
    SELECT ws_item_sk,
           SUM(ws_sales_price) AS total_sales_price,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           ca.ca_city,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ca.ca_city
),
high_value_customers AS (
    SELECT c.c_customer_id,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sales_price > 100
    GROUP BY c.c_customer_id
    HAVING total_net_profit > 1000
),
final_summary AS (
    SELECT ci.c_customer_id,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.ca_city,
           COALESCE(SUM(hvc.total_net_profit), 0) AS high_value_profit,
           COALESCE(SUM(ss.total_sales_price), 0) AS web_total_sales
    FROM customer_info ci
    LEFT JOIN high_value_customers hvc ON ci.c_customer_id = hvc.c_customer_id
    LEFT JOIN sales_summary ss ON ci.c_customer_id = ss.ws_item_sk
    GROUP BY ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.ca_city
)
SELECT f.*,
       CASE 
           WHEN f.high_value_profit > 0 AND f.web_total_sales > 500 THEN 'VIP' 
           WHEN f.web_total_sales BETWEEN 100 AND 500 THEN 'Regular' 
           ELSE 'Low Value' 
       END AS customer_status,
       CASE 
           WHEN f.cd_gender IS NULL THEN 'Unknown' 
           ELSE f.cd_gender 
       END AS final_gender
FROM final_summary f
LEFT OUTER JOIN date_dim d ON d.d_date_id = '2023-01-01'
WHERE d.d_year = 2023 
     AND (f.high_value_profit > 500 OR f.web_total_sales > 100)
ORDER BY f.total_net_profit DESC NULLS LAST
LIMIT 100 OFFSET 50;
