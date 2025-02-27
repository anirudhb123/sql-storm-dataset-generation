
WITH RECURSIVE Address_Tree AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY')
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country, at.level + 1
    FROM customer_address ca
    JOIN Address_Tree at ON ca.ca_address_sk = at.ca_address_sk
    WHERE at.level < 5
), 
Gender_Stats AS (
    SELECT cd_gender, COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE cd_purchase_estimate IS NOT NULL
    GROUP BY cd_gender
),
Sales_Aggregation AS (
    SELECT ws_item_sk, SUM(CASE WHEN ws_quantity IS NULL THEN 0 ELSE ws_quantity END) AS total_quantity,
           SUM(CASE WHEN ws_net_profit IS NULL THEN 0 ELSE ws_net_profit END) AS total_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
Join_Analysis AS (
    SELECT sa.ws_item_sk, gs.customer_count, ga.avg_purchase_estimate,
           IFNULL(sa.total_quantity, 0) AS total_quantity,
           IFNULL(sa.total_net_profit, 0) AS total_net_profit
    FROM Sales_Aggregation sa
    FULL OUTER JOIN Gender_Stats gs ON sa.ws_item_sk IS NULL OR gs.customer_count BETWEEN 0 AND 100
    LEFT JOIN Address_Tree at ON at.ca_city = 'San Francisco'
)

SELECT 
    CASE 
        WHEN total_quantity > 1000 THEN 'High Seller'
        WHEN total_quantity BETWEEN 500 AND 1000 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS seller_category,
    gs.cd_gender,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(CASE WHEN total_net_profit IS NULL THEN 0 ELSE total_net_profit END) AS net_profit_summary,
    STRING_AGG(CONCAT('Item: ', sa.ws_item_sk, ' Profits: ', sa.total_net_profit), '; ') AS item_profit_detail
FROM Join_Analysis j
JOIN customer c ON c.c_customer_sk = 1
JOIN Gender_Stats gs ON gs.customer_count > 50
GROUP BY seller_category, gs.cd_gender
HAVING SUM(total_net_profit) IS NOT NULL 
   OR MIN(total_quantity) IS NOT NULL
ORDER BY seller_category, gs.cd_gender DESC
LIMIT 100 OFFSET 20;
