
WITH recursive_addr AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country, ra.level + 1
    FROM customer_address ca
    JOIN recursive_addr ra ON ra.ca_city = ca.ca_city AND ra.ca_state <> ca.ca_state
    WHERE ra.level < 3
),
gender_stats AS (
    SELECT cd_gender, COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
),
aggregate_sales AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS order_rank
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(MAX(cs_ext_sales_price), 0) AS max_catalog_price,
        COALESCE(MAX(ss_ext_sales_price), 0) AS max_store_price
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_current_price
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    gs.cd_gender,
    gs.customer_count,
    gs.avg_purchase_estimate,
    COUNT(DISTINCT g.ws_bill_cdemo_sk) AS total_customers,
    MAX(id.i_current_price) AS highest_price_item,
    SUM(id.max_catalog_price - id.max_store_price) AS price_difference
FROM recursive_addr ca
JOIN gender_stats gs ON gs.customer_count > 10
LEFT JOIN aggregate_sales g ON g.ws_bill_cdemo_sk = gs.cd_gender
LEFT JOIN item_details id ON id.i_current_price > 100
WHERE 
    ca.ca_country IS NOT NULL 
    AND (gs.cd_gender IS NOT NULL OR gs.avg_purchase_estimate > 0)
    AND id.max_catalog_price > 0
GROUP BY ca.ca_city, ca.ca_state, ca.ca_country, gs.cd_gender, gs.customer_count, gs.avg_purchase_estimate
HAVING COUNT(g.ws_bill_cdemo_sk) > 5
ORDER BY ca.ca_state, gs.customer_count DESC,
         NULLIF(gs.avg_purchase_estimate, 0) DESC, 
         price_difference ASC;
