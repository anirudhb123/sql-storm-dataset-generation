
WITH RECURSIVE InventoryHierarchy AS (
    SELECT 
        w.w_warehouse_id,
        i.i_item_id,
        inv.inv_quantity_on_hand,
        1 AS level
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    WHERE 
        inv.inv_quantity_on_hand > 0
    
    UNION ALL
    
    SELECT 
        ih.w_warehouse_id,
        i.i_item_id,
        i.i_current_price * ih.inv_quantity_on_hand AS estimated_value,
        ih.level + 1
    FROM 
        InventoryHierarchy ih
    JOIN 
        item i ON i.i_item_id = ih.i_item_id
    WHERE 
        i.i_current_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        r.returned_date_sk,
        r.return_time_sk,
        SUM(r.return_quantity) AS total_returned,
        SUM(r.return_amt) AS total_amount_refunded
    FROM 
        store_returns r
    WHERE 
        r.return_quantity > 0
    GROUP BY 
        r.returned_date_sk, r.return_time_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    DATE(DATEADD(DAY, 0, d.d_date_sk)) AS sold_date,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returned, 0) AS total_returns,
    COALESCE(cr.total_amount_refunded, 0) AS total_refunds,
    COALESCE(ih.inv_quantity_on_hand, 0) AS inventory_count,
    ih.w_warehouse_id AS warehouse_id,
    ih.item_id,
    (COALESCE(ss.total_net_profit, 0) - COALESCE(cr.total_amount_refunded, 0)) AS net_profit_after_returns
FROM 
    date_dim d
LEFT JOIN 
    SalesSummary ss ON d.d_date_sk = ss.ws_sold_date_sk
LEFT JOIN 
    CustomerReturns cr ON d.d_date_sk = cr.returned_date_sk
LEFT JOIN 
    InventoryHierarchy ih ON 1=1
WHERE 
    d.d_year = 2023
ORDER BY 
    sold_date, warehouse_id, item_id
LIMIT 100;
