
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS depth
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country, depth + 1
    FROM customer_address AS ca
    JOIN address_hierarchy AS ah ON ca_state = ah.ca_state AND ca_city <> ah.ca_city
    WHERE depth < 5
),
demographics_summary AS (
    SELECT cd_gender, COUNT(*) AS demographic_count, 
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           SUM(CASE WHEN cd_dep_count IS NULL THEN 0 ELSE cd_dep_count END) AS total_dependencies,
           STRING_AGG(DISTINCT cd_credit_rating, ', ') AS credit_ratings
    FROM customer_demographics
    GROUP BY cd_gender
),
sales_data AS (
    SELECT 'web' AS sales_source, 
           SUM(ws_net_profit) AS total_profit, 
           SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_web_site_sk
    UNION ALL
    SELECT 'catalog' AS sales_source, 
           SUM(cs_net_profit) AS total_profit, 
           SUM(cs_quantity) AS total_quantity
    FROM catalog_sales
    GROUP BY cs_call_center_sk
    UNION ALL
    SELECT 'store' AS sales_source, 
           SUM(ss_net_profit) AS total_profit, 
           SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_store_sk
),
average_sales AS (
    SELECT sales_source,
           AVG(total_profit) AS avg_profit,
           SUM(total_quantity) AS total_quantity_sold
    FROM sales_data
    GROUP BY sales_source
)
SELECT ah.ca_city, ah.ca_state, ah.ca_country,
       ds.cd_gender, ds.demographic_count, ds.avg_purchase_estimate,
       ss.avg_profit, ss.total_quantity_sold
FROM address_hierarchy ah
FULL OUTER JOIN demographics_summary ds ON ah.ca_city = ds.cd_gender
LEFT JOIN average_sales ss ON ds.demographic_count = ss.total_quantity_sold AND ds.cd_gender IS NOT NULL
WHERE (ah.ca_country LIKE '%land' OR ah.ca_country IS NULL)
AND (ds.avg_purchase_estimate > 10000 OR ds.cd_credit_rating IS NOT NULL)
ORDER BY ah.ca_state, ds.cd_gender DESC, ss.avg_profit DESC
LIMIT 100;
