
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT ch.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE level < 5
),
ReturningItems AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_item_sk
),
WebReturns AS (
    SELECT wr_item_sk, SUM(wr_return_quantity) AS total_web_returned
    FROM web_returns
    GROUP BY wr_item_sk
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_web_sales,
        SUM(ws_net_profit) AS total_web_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
InventoryCounts AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ri.total_returned, 0) as total_store_returns,
    COALESCE(wr.total_web_returned, 0) as total_web_returns,
    COALESCE(sd.total_web_sales, 0) as total_web_sales,
    COALESCE(sd.total_web_profit, 0) as total_web_profit,
    COALESCE(ic.total_inventory, 0) as total_inventory,
    CASE
        WHEN COALESCE(sd.total_web_sales, 0) > 0 THEN 
            (COALESCE(sd.total_web_profit, 0) / COALESCE(sd.total_web_sales, 0)) * 100
        ELSE 0
    END AS profit_margin_percentage
FROM item i
LEFT OUTER JOIN ReturningItems ri ON i.i_item_sk = ri.sr_item_sk
LEFT OUTER JOIN WebReturns wr ON i.i_item_sk = wr.wr_item_sk
LEFT OUTER JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT OUTER JOIN InventoryCounts ic ON i.i_item_sk = ic.inv_item_sk
WHERE COALESCE(ri.total_returned, 0) + COALESCE(wr.total_web_returned, 0) > 10
ORDER BY profit_margin_percentage DESC
LIMIT 50;
