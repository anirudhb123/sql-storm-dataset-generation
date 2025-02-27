
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_return_time_sk, 
        sr_item_sk, 
        sr_customer_sk, 
        sr_return_quantity, 
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS return_rnk
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_return_quantity, 
        COUNT(DISTINCT sr_customer_sk) AS unique_customers
    FROM RankedReturns
    WHERE return_rnk <= 5
    GROUP BY sr_item_sk
),
HighReturnItems AS (
    SELECT 
        ir.i_item_id, 
        ir.i_item_desc, 
        ar.total_return_quantity, 
        ar.unique_customers,
        CASE 
            WHEN ar.unique_customers = 0 THEN NULL
            ELSE ar.total_return_quantity / ar.unique_customers 
        END AS average_returns_per_customer
    FROM item ir 
    JOIN AggregateReturns ar ON ir.i_item_sk = ar.sr_item_sk
    WHERE ar.total_return_quantity > (SELECT AVG(total_return_quantity) FROM AggregateReturns) 
)
SELECT 
    w.w_warehouse_name,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    JSON_AGG(ROW_TO_JSON(h)) AS high_return_items
FROM warehouse w
LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN HighReturnItems h ON ws.ws_item_sk = h.i_item_id
GROUP BY w.w_warehouse_name
HAVING SUM(ws.ws_net_profit) IS NOT NULL 
AND COUNT(h.i_item_id) > 0
ORDER BY total_net_profit DESC NULLS LAST
LIMIT 10;
