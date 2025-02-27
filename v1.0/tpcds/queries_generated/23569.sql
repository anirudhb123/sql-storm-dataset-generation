
WITH RECURSIVE dollar_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 
           CASE 
               WHEN ib_lower_bound >= 0 THEN CAST(NULL AS integer)
               ELSE NULL
           END AS income_range
    FROM income_band
    UNION ALL
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound,
           (ib_upper_bound - ib_lower_bound) AS income_range
    FROM income_band
    WHERE ib_lower_bound < ib_upper_bound
), 
customer_stats AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           SUM(ws.ws_net_paid) AS total_spent,
           COUNT(DISTINCT c.c_customer_sk) AS total_customers,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
), 
recurring_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           MAX(ws.ws_sales_price) AS max_price,
           MIN(ws.ws_sales_price) AS min_price,
           AVG(ws.ws_sales_price) AS avg_price
    FROM customer c
    INNER JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    ca.ca_country,
    ca.ca_state,
    SUM(cs.cs_net_profit + COALESCE(ws.ws_net_profit, 0)) as total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    RANK() OVER (PARTITION BY ca.ca_country ORDER BY SUM(cs.cs_net_profit + COALESCE(ws.ws_net_profit, 0)) DESC) AS country_rank,
    (SELECT COUNT(*) FROM (SELECT DISTINCT c.c_customer_id FROM customer c WHERE c.c_birth_month BETWEEN 1 AND 12) AS unique_customers) as unique_customer_count,
    CALELEMT(c.c_first_name, cd.cd_marital_status) AS marital_name
FROM customer_address ca
LEFT JOIN store_sales ss ON ca.ca_address_sk = ss.ss_addr_sk
FULL OUTER JOIN catalog_sales cs ON ca.ca_address_sk = cs.cs_bill_addr_sk
LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE (cd.cd_marital_status IS NOT NULL OR cd.cd_gender = 'F')
  AND (cd.cd_purchase_estimate IS NOT NULL OR cd.cd_credit_rating IS NOT NULL)
  AND (ca.ca_country IN ('USA', 'Canada') OR ca.ca_state IS NOT NULL)
GROUP BY ca.ca_country, ca.ca_state, c.c_first_name, c.c_last_name
HAVING SUM(cs.cs_net_profit + COALESCE(ws.ws_net_profit, 0)) > 1000.00
ORDER BY total_profit DESC, country_rank ASC;
