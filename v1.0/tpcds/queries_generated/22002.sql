
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ah.level < 5
),
ranked_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) as rnk,
           MAX(CASE WHEN cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END) AS marital_status,
           SUM(cd_dep_count) OVER (PARTITION BY c.c_customer_sk) AS total_dependents
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd_purchase_estimate > 1000
),
filtered_sales AS (
    SELECT ws.ws_shipping_customer_sk, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit,
           DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 5000
    GROUP BY ws.ws_shipping_customer_sk
),
double_returns AS (
    SELECT cr_returning_customer_sk, SUM(cr_return_quantity) AS total_doubled_returns
    FROM catalog_returns
    WHERE cr_return_quantity > 1
    GROUP BY cr_returning_customer_sk
),
all_data AS (
    SELECT rc.c_customer_sk, rc.c_first_name, rc.c_last_name, 
           fs.total_quantity, fs.total_profit, 
           dr.total_doubled_returns,
           ah.ca_city, ah.ca_state, ah.ca_country
    FROM ranked_customers rc
    LEFT JOIN filtered_sales fs ON rc.c_customer_sk = fs.ws_shipping_customer_sk
    LEFT JOIN double_returns dr ON rc.c_customer_sk = dr.cr_returning_customer_sk
    JOIN address_hierarchy ah ON rc.c_customer_sk = ah.ca_address_sk
)
SELECT * 
FROM all_data
WHERE (total_profit IS NOT NULL OR total_quantity IS NOT NULL)
AND (COALESCE(total_quantity, 0) > 10 OR total_profit > 500)
ORDER BY (SELECT COUNT(*) FROM address_hierarchy) DESC, total_profit DESC, total_quantity ASC
LIMIT 100;
