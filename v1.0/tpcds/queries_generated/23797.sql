
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 
        sr_item_sk, sr_return_quantity
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
SalesWithNullCheck AS (
    SELECT 
        ir.inv_item_sk,
        COALESCE(rs.ws_net_paid, 0) AS net_sales,
        COALESCE(rr.total_return_amt, 0) AS total_returns,
        (COALESCE(rs.ws_net_paid, 0) - COALESCE(rr.total_return_amt, 0)) AS net_gain_loss,
        ir.total_quantity_on_hand
    FROM 
        InventoryStatus ir
    LEFT JOIN 
        RankedSales rs ON ir.inv_item_sk = rs.ws_item_sk
    LEFT JOIN 
        RecentReturns rr ON ir.inv_item_sk = rr.sr_item_sk
    WHERE 
        ir.total_quantity_on_hand IS NOT NULL
)
SELECT 
    s.ws_item_sk,
    s.net_sales,
    s.total_returns,
    CASE 
        WHEN s.total_quantity_on_hand >= 100 THEN 'High Inventory'
        WHEN s.total_quantity_on_hand < 100 AND s.total_quantity_on_hand > 0 THEN 'Low Inventory'
        ELSE 'Out of Stock'
    END AS inventory_status,
    CASE 
        WHEN s.net_gain_loss > 0 THEN 'Profitable'
        WHEN s.net_sales = 0 AND s.total_returns > 0 THEN 'Return Only'
        ELSE 'Loss'
    END AS profitability_status
FROM 
    SalesWithNullCheck s
ORDER BY 
    s.net_gain_loss DESC, s.net_sales DESC
LIMIT 50;
