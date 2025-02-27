
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
), 
BestSellers AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.item_rank <= 5
), 
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        sr_item_sk
), 
NetSalesWithReturns AS (
    SELECT 
        bs.ws_item_sk,
        bs.total_quantity,
        bs.total_net_profit,
        COALESCE(ar.total_returns, 0) AS total_returns,
        (bs.total_net_profit - COALESCE(ar.total_returns, 0) * (SELECT avg(bs.net_profit) FROM web_sales bs WHERE net_profit >= 0)) AS adjusted_profit
    FROM 
        BestSellers bs
    LEFT JOIN 
        AggregateReturns ar ON bs.ws_item_sk = ar.sr_item_sk
)
SELECT 
    ws.ws_item_sk,
    ws.total_quantity,
    ws.total_net_profit,
    ws.total_returns,
    CASE 
        WHEN ws.adjusted_profit > 0 THEN 'Profitable'
        WHEN ws.adjusted_profit = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS sales_status,
    STRING_AGG(DISTINCT i.i_item_id) AS item_ids,
    COUNT(DISTINCT sw.s_warehouse_sk) AS warehouse_count
FROM 
    NetSalesWithReturns ws
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    inventory inv ON inv.inv_item_sk = ws.ws_item_sk
JOIN 
    warehouse sw ON sw.w_warehouse_sk = inv.inv_warehouse_sk AND sw.w_country = 'USA'
WHERE 
    i.i_current_price BETWEEN 10.00 AND 100.00 
    AND (ws.total_net_profit IS NULL OR ws.total_net_profit > 0)
GROUP BY 
    ws.ws_item_sk, ws.total_quantity, ws.total_net_profit, ws.total_returns, ws.adjusted_profit;
