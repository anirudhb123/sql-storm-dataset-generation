
WITH CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT DISTINCT sr_returned_date_sk FROM store_returns)
    GROUP BY 
        ws_item_sk
),
ItemInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
SalesAndReturns AS (
    SELECT 
        is.ws_item_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        is.total_sold,
        is.total_net_profit,
        inv.total_quantity_on_hand
    FROM 
        ItemSales is
    LEFT JOIN 
        CustomerReturns cr ON is.ws_item_sk = cr.sr_item_sk
    LEFT JOIN 
        ItemInventory inv ON is.ws_item_sk = inv.inv_item_sk
)
SELECT 
    si.ws_item_sk,
    si.total_returns,
    si.total_return_quantity,
    si.total_return_amount,
    si.total_return_tax,
    si.total_sold,
    si.total_net_profit,
    si.total_quantity_on_hand,
    CASE 
        WHEN si.total_net_profit > 0 THEN 'Profitable'
        WHEN si.total_net_profit < 0 THEN 'Unprofitable'
        ELSE 'Break-even'
    END AS profitability_status,
    CASE
        WHEN si.total_quantity_on_hand = 0 THEN 'Out of Stock'
        WHEN si.total_quantity_on_hand < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    SalesAndReturns si
WHERE 
    (si.total_returns > 0 OR si.total_sold > 50)
ORDER BY 
    si.total_net_profit DESC,
    si.total_returns DESC,
    si.stock_status DESC;
