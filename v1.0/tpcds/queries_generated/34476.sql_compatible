
WITH RECURSIVE InventoryCTE AS (
    SELECT inv_warehouse_sk, inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand < 10
    UNION ALL
    SELECT inv.inv_warehouse_sk, inv.inv_item_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    INNER JOIN InventoryCTE it ON inv.inv_item_sk = it.inv_item_sk
    WHERE inv.inv_quantity_on_hand < it.inv_quantity_on_hand
),
TopItems AS (
    SELECT i.i_item_id, SUM(ws.ws_quantity) AS total_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk >= 20230101
    GROUP BY i.i_item_id
    HAVING SUM(ws.ws_quantity) > 100
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    ORDER BY customer_count DESC
)
SELECT 
    ca.ca_state,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
    AVG(CASE WHEN ws.ws_ship_mode_sk IS NULL THEN 0 ELSE ws.ws_ship_mode_sk END) AS avg_ship_mode
FROM customer_address ca
LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
LEFT JOIN CustomerDemographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN InventoryCTE invCTE ON invCTE.inv_item_sk = ws.ws_item_sk
WHERE ca.ca_country = 'USA'
  AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
  AND invCTE.inv_quantity_on_hand < 20
GROUP BY ca.ca_state
HAVING SUM(COALESCE(ws.ws_net_profit, 0)) > (
    SELECT AVG(total_sales) 
    FROM TopItems
)
ORDER BY total_net_profit DESC;
