
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2450000 -- Example date range
    GROUP BY 
        ws_item_sk, ws_order_number
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_profit,
        is.total_quantity_on_hand,
        ss.rank_profit
    FROM 
        SalesSummary ss
    JOIN 
        InventoryStatus is ON ss.ws_item_sk = is.inv_item_sk
    WHERE 
        ss.rank_profit <= 10
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS unique_returning_customers
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_profit,
    ti.total_quantity_on_hand,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned,
    COALESCE(cr.unique_returning_customers, 0) AS unique_customers
FROM 
    TopItems ti
LEFT JOIN 
    CustomerReturns cr ON ti.ws_item_sk = cr.cr_item_sk
ORDER BY 
    ti.total_profit DESC;
