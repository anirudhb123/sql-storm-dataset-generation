
WITH RecursiveInventory AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand,
           ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM inventory
), RecentReturns AS (
    SELECT cr_item_sk, SUM(cr_return_quantity) AS total_returned, 
           SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY cr_item_sk
), SalesData AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity_sold,
           AVG(ws_sales_price) AS avg_sales_price, 
           MAX(ws_net_profit) AS max_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
), ItemPerformance AS (
    SELECT i.i_item_sk, i.i_item_desc, COALESCE(SD.total_quantity_sold, 0) AS total_qty,
           COALESCE(RR.total_returned, 0) AS total_returned,
           COALESCE(RR.total_return_amount, 0) AS total_return_amount,
           COALESCE(SD.avg_sales_price, 0) AS avg_sales_price,
           COALESCE(SD.max_net_profit, 0) AS max_net_profit,
           ROUND(100.0 * COALESCE(RR.total_returned, 0) / NULLIF(SD.total_quantity_sold, 0), 2) AS return_rate
    FROM item i
    LEFT JOIN SalesData SD ON i.i_item_sk = SD.ws_item_sk
    LEFT JOIN RecentReturns RR ON i.i_item_sk = RR.cr_item_sk
    WHERE i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
      AND (i.i_item_desc LIKE '%Special%' OR i.i_item_desc LIKE '%Limited%')
    ORDER BY return_rate DESC
)
SELECT i.ItemDesc, i.total_qty, i.total_returned, i.avg_sales_price, 
       i.max_net_profit, i.return_rate,
       ROW_NUMBER() OVER (ORDER BY i.return_rate) AS rank
FROM ItemPerformance i
WHERE i.return_rate IS NOT NULL
  AND i.return_rate > 0
  AND NOT EXISTS (
    SELECT 1
    FROM store s
    WHERE s.s_state IN ('CA', 'NY')
      AND s.s_open_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
      AND s.s_closed_date_sk IS NULL
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = i.i_item_sk
            AND ws.ws_ship_date_sk = s.s_store_sk
            AND ws.ws_bill_customer_sk IS NOT NULL
      )
)
ORDER BY i.return_rate DESC
