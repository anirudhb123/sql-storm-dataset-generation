
WITH RECURSIVE InventoryCTE AS (
    SELECT i_item_sk, 
           SUM(inv_quantity_on_hand) AS total_quantity,
           ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM inventory
    GROUP BY i_item_sk
),
CustomerStats AS (
    SELECT c_current_cdemo_sk,
           COUNT(c_customer_sk) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           MAX(cd_credit_rating) AS highest_credit_rating
    FROM customer
    LEFT JOIN customer_demographics 
        ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_current_cdemo_sk
),
SalesData AS (
    SELECT ws.web_site_sk,
           SUM(ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws_order_number) AS total_orders,
           RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 -- focusing on 2023
    GROUP BY ws.web_site_sk
)
SELECT ca.*, 
       cs.customer_count,
       cs.avg_purchase_estimate,
       sd.total_profit,
       sd.total_orders
FROM customer_address ca
LEFT JOIN CustomerStats cs ON ca.ca_address_sk = cs.c_current_cdemo_sk
FULL OUTER JOIN SalesData sd ON sd.web_site_sk = ca.ca_address_sk
WHERE (ca.ca_state IS NOT NULL OR ca.ca_city IS NOT NULL)
  AND (LOWER(ca.ca_country) LIKE '%united%' OR ca.ca_zip IS NULL)
ORDER BY (CASE WHEN cs.customer_count IS NULL THEN 0 ELSE cs.customer_count END) DESC,
         (CASE WHEN sd.total_profit IS NULL THEN 0 ELSE sd.total_profit END) DESC;
