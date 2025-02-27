
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 as level
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_country = ah.ca_country
    WHERE ah.level < 5
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           CASE 
               WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
               WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
               WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END AS purchase_category,
           COALESCE(ah.ca_city, 'Unknown') AS city,
           COALESCE(ah.ca_state, 'Unknown') AS state,
           COALESCE(ah.ca_country, 'Unknown') AS country
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN address_hierarchy ah ON c.c_current_addr_sk = ah.ca_address_sk
),
sales_summary AS (
    SELECT SUM(ws_net_profit) AS total_profit, ws_ship_mode_sk
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY ws_ship_mode_sk
),
purchase_details AS (
    SELECT c.c_customer_sk, SUM(ws_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE ws.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND
          (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk
)
SELECT ci.c_first_name, ci.c_last_name, ci.purchase_category, ss.total_profit,
       pd.total_sales, 
       CASE WHEN pd.sales_rank = 1 THEN 'Top Buyer'
            ELSE 'Regular Buyer'
       END AS buyer_type,
       sm.sm_type
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_ship_mode_sk
LEFT JOIN purchase_details pd ON ci.c_customer_sk = pd.c_customer_sk
JOIN ship_mode sm ON ss.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ci.city LIKE '%San%' 
  AND (ci.state IS NULL OR ci.state != 'CA') 
  AND (ci.purchase_category IN ('Medium', 'High') OR ci.purchase_category IS NULL)
ORDER BY total_sales DESC, ci.c_last_name, ci.c_first_name
LIMIT 50;
