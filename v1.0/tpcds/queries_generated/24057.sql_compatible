
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 0 AS level
    FROM customer_address
    WHERE ca_country = 'USA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_state = ah.ca_state AND ah.level < 5
),
CustomerInfo AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender,
           cd.cd_marital_status, cd.cd_purchase_estimate, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate BETWEEN 1000 AND 5000
),
FilteredReturns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
    GROUP BY sr_item_sk
),
AggregatedSales AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_sold,
           SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_item_sk
),
FinalReport AS (
    SELECT ci.c_first_name, ci.c_last_name, 
           ah.ca_city, ah.ca_state,
           COALESCE(fs.total_sold, 0) AS total_sold,
           COALESCE(fr.total_returns, 0) AS total_returns,
           (COALESCE(fs.total_sold, 0) - COALESCE(fr.total_returns, 0)) AS net_sold,
           CASE 
               WHEN ci.rank = 1 THEN 'Top Customer'
               ELSE 'Regular Customer'
           END AS customer_type
    FROM CustomerInfo ci
    JOIN AddressHierarchy ah ON ci.c_customer_sk = ah.ca_address_sk
    LEFT JOIN AggregatedSales fs ON ci.c_customer_sk = fs.ws_item_sk
    LEFT JOIN FilteredReturns fr ON fs.ws_item_sk = fr.sr_item_sk
    WHERE (COALESCE(fs.total_sold, 0) - COALESCE(fr.total_returns, 0)) > 0 
          OR (ci.cd_gender = 'F' AND ah.ca_city IS NOT NULL)
)
SELECT * 
FROM FinalReport
WHERE customer_type = 'Top Customer'
AND net_sold > (
    SELECT AVG(net_sold) 
    FROM FinalReport
    WHERE net_sold IS NOT NULL
)
ORDER BY net_sold DESC
FETCH FIRST 100 ROWS ONLY;
