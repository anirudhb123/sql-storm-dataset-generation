
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
InventoryOverview AS (
    SELECT 
        inv.inv_item_sk AS item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY inv.inv_item_sk
),
SalesAnalysis AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(r.total_inventory, 0) AS available_inventory,
        COALESCE(s.total_quantity, 0) AS sold_quantity,
        COALESCE(s.total_profit, 0) AS net_profit,
        CASE 
            WHEN COALESCE(s.total_profit, 0) > 1000 THEN 'High' 
            WHEN COALESCE(s.total_profit, 0) BETWEEN 500 AND 1000 THEN 'Medium' 
            ELSE 'Low' 
        END AS profit_category,
        (SELECT COUNT(*) FROM customer_address WHERE ca_state = 'CA') AS ca_address_count
    FROM item i
    LEFT JOIN InventoryOverview r ON i.i_item_sk = r.item_sk
    LEFT JOIN RankedSales s ON i.i_item_sk = s.ws_item_sk AND s.item_rank = 1
    WHERE LOWER(i.i_item_desc) LIKE '%widget%'
)
SELECT 
    sa.i_item_id,
    sa.i_item_desc,
    sa.available_inventory,
    sa.sold_quantity,
    sa.net_profit,
    sa.profit_category,
    (SELECT AVG(cd_purchase_estimate) 
     FROM customer_demographics 
     WHERE cd_dep_count IS NOT NULL) AS avg_purchase_estimate,
    (SELECT LISTAGG(DISTINCT ca.ca_city, ', ') 
     WITHIN GROUP (ORDER BY ca.ca_city) 
     FROM customer_address ca 
     WHERE ca.ca_state IS NOT NULL 
     AND ca.ca_country = 'USA') AS us_cities
FROM SalesAnalysis sa
WHERE sa.available_inventory > (SELECT AVG(total_inventory) FROM InventoryOverview) 
ORDER BY sa.net_profit DESC 
LIMIT 10;
