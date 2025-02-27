
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL 
    AND ws.ws_net_profit IS NOT NULL 
    AND ws.ws_net_profit BETWEEN 0 AND 1000
), 
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt
    FROM store_returns 
    WHERE sr_return_quantity IS NOT NULL 
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_amt) > 500
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RankedSales.ws_sales_price, 0) AS current_sales_price,
    CASE 
        WHEN HighValueReturns.total_returned_quantity IS NOT NULL THEN HighValueReturns.total_returned_quantity
        ELSE 0 
    END AS return_quantity,
    CASE 
        WHEN HighValueReturns.total_returned_amt IS NOT NULL THEN HighValueReturns.total_returned_amt
        ELSE 0 
    END AS return_amount,
    s.s_store_name,
    sm.sm_carrier
FROM item i
LEFT JOIN RankedSales ON i.i_item_sk = RankedSales.ws_item_sk AND RankedSales.rn = 1
LEFT JOIN store s ON s.s_store_sk = i.i_manager_id
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = (SELECT ship_mode_sk FROM catalog_sales cs WHERE cs.cs_item_sk = i.i_item_sk LIMIT 1)
LEFT JOIN HighValueReturns ON i.i_item_sk = HighValueReturns.sr_item_sk
WHERE i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_current_price IS NOT NULL)
AND (s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > current_date)
ORDER BY return_amount DESC, current_sales_price DESC
LIMIT 100;
