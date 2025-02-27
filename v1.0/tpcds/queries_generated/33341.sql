
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_net_paid
    FROM web_sales ws
    JOIN SalesCTE s ON ws.sold_date_sk < s.ws_sold_date_sk
    WHERE ws_item_sk = s.ws_item_sk
    LIMIT 1000
),
CustomerAddress AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state = 'CA'
),
IncomeStats AS (
    SELECT cd_demo_sk, 
           COUNT(*) AS customer_count,
           SUM(cd_purchase_estimate) AS total_estimated_purchase,
           AVG(cd_dep_count) AS average_dependent_count
    FROM customer_demographics
    GROUP BY cd_demo_sk
),
SalesAggregates AS (
    SELECT COALESCE(ws_item_sk, cs_item_sk) AS item_sk,
           SUM(ws_quantity) AS total_web_sales,
           SUM(cs_quantity) AS total_catalog_sales
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY COALESCE(ws_item_sk, cs_item_sk)
),
FinalResults AS (
    SELECT c.ca_city,
           c.ca_state,
           s.item_sk,
           s.total_web_sales,
           s.total_catalog_sales,
           i.customer_count,
           i.total_estimated_purchase,
           i.average_dependent_count
    FROM CustomerAddress c
    LEFT JOIN SalesAggregates s ON c.ca_city = 'Los Angeles' AND c.ca_state = 'CA'
    LEFT JOIN IncomeStats i ON i.cd_demo_sk = (SELECT cd_demo_sk FROM customer WHERE c_current_addr_sk = ca_address_sk LIMIT 1)
)
SELECT 
    city,
    state,
    item_sk,
    total_web_sales,
    total_catalog_sales,
    customer_count,
    total_estimated_purchase,
    average_dependent_count
FROM FinalResults
WHERE (total_web_sales > 100 OR total_catalog_sales > 100) 
  AND total_estimated_purchase IS NOT NULL
ORDER BY total_estimated_purchase DESC
LIMIT 50;
