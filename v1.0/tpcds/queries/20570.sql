
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(*) AS return_count
    FROM RankedReturns
    WHERE return_rank <= 5
    GROUP BY sr_item_sk
),
HighReturnItems AS (
    SELECT 
        ar.sr_item_sk,
        ar.total_returned,
        ar.return_count,
        i.i_item_desc,
        i.i_current_price,
        i.i_category
    FROM AggregateReturns ar
    JOIN item i ON ar.sr_item_sk = i.i_item_sk
    WHERE ar.total_returned > (
        SELECT AVG(total_returned) FROM AggregateReturns
    )
),
SalesOverview AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN HighReturnItems hri ON ws.ws_item_sk = hri.sr_item_sk
    GROUP BY ws.ws_item_sk
)
SELECT 
    w.w_warehouse_name,
    hri.i_item_desc,
    hri.total_returned,
    so.total_sales,
    so.total_orders,
    so.avg_sales_price,
    CASE 
        WHEN hri.total_returned > so.total_sales THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_category
FROM SalesOverview so
JOIN HighReturnItems hri ON so.ws_item_sk = hri.sr_item_sk
JOIN warehouse w ON w.w_warehouse_sk IN (
    SELECT DISTINCT inv.inv_warehouse_sk 
    FROM inventory inv 
    WHERE inv.inv_quantity_on_hand < 10 AND inv.inv_item_sk = hri.sr_item_sk
)
ORDER BY w.w_warehouse_name, hri.i_item_desc;
