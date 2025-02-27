
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country
    FROM customer_address a
    JOIN address_cte c ON a.ca_city = c.ca_city AND a.ca_country = c.ca_country
    WHERE a.ca_state IS NULL
), demographic_analysis AS (
    SELECT cd.cd_gender,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           AVG(cd.cd_purchase_estimate) AS avg_estimate,
           SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
           SUM(CASE WHEN cd.cd_marital_status IS NULL THEN 1 ELSE 0 END) AS unknown_married_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
    GROUP BY cd.cd_gender
), ship_mode_summary AS (
    SELECT sm.sm_ship_mode_id,
           AVG(ws.ws_ext_sales_price) AS avg_sales_price,
           SUM(CASE WHEN ws.ws_sales_price IS NULL THEN ws.ws_net_profit ELSE 0 END) AS net_profit_with_sales_null,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM ship_mode sm
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
), performance AS (
    SELECT d.cd_gender,
           d.customer_count,
           d.avg_estimate,
           s.sm_ship_mode_id,
           s.avg_sales_price,
           s.net_profit_with_sales_null,
           s.total_orders
    FROM demographic_analysis d
    JOIN ship_mode_summary s ON d.customer_count > 100
)
SELECT p.cd_gender,
       p.sm_ship_mode_id,
       COALESCE(p.avg_sales_price, 0) AS avg_sales_price,
       COALESCE(p.total_orders, 0) AS total_orders,
       NULLIF((SELECT COUNT(*) FROM address_cte WHERE ca_country = 'Unknown Country'), 0) AS unknown_country_count,
       CASE  
           WHEN p.customer_count > 200 THEN 'High Value' 
           WHEN p.customer_count BETWEEN 100 AND 200 THEN 'Medium Value' 
           ELSE 'Low Value' 
       END AS customer_value_category
FROM performance p
LEFT JOIN customer_address ca ON ca.ca_city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_country = 'USA')
WHERE NOT EXISTS (
    SELECT 1 
    FROM customer c 
    WHERE c.c_current_cdemo_sk IS NULL
);
