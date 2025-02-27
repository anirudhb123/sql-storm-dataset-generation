
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           cd.cd_dep_count,
           cd.cd_dep_employed_count,
           cd.cd_dep_college_count,
           LEVEL AS hierarchy_level
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT ch.c_customer_sk,
           ch.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           cd.cd_dep_count,
           cd.cd_dep_employed_count,
           cd.cd_dep_college_count,
           LEVEL + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN c.c_customer_id END) AS female_customers,
    COUNT(DISTINCT CASE WHEN cd.cd_gender = 'M' THEN c.c_customer_id END) AS male_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN cd.cd_dep_count ELSE 0 END) AS total_dependents_married,
    SUM(CASE WHEN cd.cd_marital_status = 'S' THEN cd.cd_dep_count ELSE 0 END) AS total_dependents_single,
    MAX(cd.cd_purchase_estimate) OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_city) AS max_purchase_city
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_city IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY total_customers DESC
LIMIT 50;

WITH ItemSales AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS total_sales_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
)
SELECT i.i_item_id,
       ISNULL(total_sales_quantity, 0) AS sales_quantity,
       COALESCE(total_net_profit, 0.00) AS net_profit,
       CASE 
           WHEN order_count IS NULL THEN 'N/A'
           WHEN order_count > 100 THEN 'High Demand'
           WHEN order_count BETWEEN 50 AND 100 THEN 'Moderate Demand'
           ELSE 'Low Demand'
       END AS demand_category
FROM ItemSales i
LEFT JOIN (SELECT DISTINCT i_item_id FROM item) it ON i.i_item_id = it.i_item_id
WHERE total_sales_quantity IS NOT NULL
ORDER BY net_profit DESC
FETCH FIRST 10 ROWS ONLY;
