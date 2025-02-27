
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, ca_zip
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, ca.city, ca_state, 'Unknown Country' AS ca_country, '00000' AS ca_zip
    FROM customer_address a 
    JOIN address_cte cte ON a.ca_state = cte.ca_state 
    WHERE a.ca_city IS NULL AND a.ca_country IS NOT NULL
),
demographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_purchase_estimate, cd_credit_rating,
           RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
),
date_filter AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year >= 2020 AND d_year <= 2023
),
sales_data AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_sales
    FROM web_sales ws
    INNER JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_open_date_sk IS NOT NULL AND ws.ws_sales_price > 0
    GROUP BY ws.ws_item_sk
),
sales_with_return AS (
    SELECT sd.ws_item_sk,
           sd.total_net_profit,
           COALESCE(SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_amt ELSE 0 END), 0) AS total_returned
    FROM sales_data sd
    LEFT JOIN store_returns sr ON sd.ws_item_sk = sr.sr_item_sk
    GROUP BY sd.ws_item_sk, sd.total_net_profit
)
SELECT ca.ca_city, 
       ca.ca_state, 
       COUNT(DISTINCT c.c_customer_sk) AS customer_count,
       SUM(swr.total_net_profit) AS total_net_profit,
       MAX(dmo.cd_purchase_estimate) AS highest_purchase_estimate,
       COUNT(dmo.rank) FILTER (WHERE dmo.rank < 5) AS top_demographics
FROM customer c
JOIN address_cte ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN demographics dmo ON c.c_current_cdemo_sk = dmo.cd_demo_sk
JOIN sales_with_return swr ON swr.ws_item_sk = c.c_customer_sk
JOIN date_filter df ON df.d_date_sk = swr.ws_item_sk
WHERE ca.ca_country IS NOT NULL
AND (ca.ca_zip IS NOT NULL OR ca.ca_city LIKE '%City%')
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(swr.total_net_profit) > 1000
ORDER BY total_net_profit DESC NULLS LAST;
