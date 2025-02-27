
WITH RECURSIVE InventoryCTE AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        1 AS Level
    FROM 
        inventory inv 
    WHERE 
        inv.inv_quantity_on_hand > 0

    UNION ALL

    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand * 2,
        Level + 1
    FROM 
        inventory inv
    JOIN InventoryCTE ic ON inv.inv_item_sk = ic.inv_item_sk
    WHERE 
        Level < 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr.sr_ticket_number) AS return_count,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_quantity
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(ic.inv_quantity_on_hand, 0) AS inventory_quantity,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) > 0 THEN (COALESCE(cr.total_returned, 0) / COALESCE(sd.total_sales, 0)) * 100
        ELSE 0 
    END AS return_rate_percentage,
    sd.sales_rank
FROM 
    item id
LEFT JOIN 
    SalesData sd ON id.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON id.i_item_sk = cr.sr_item_sk
LEFT JOIN 
    InventoryCTE ic ON id.i_item_sk = ic.inv_item_sk
WHERE 
    id.i_current_price > 50 
    AND (sd.sales_rank IS NULL OR sd.sales_rank <= 10)
ORDER BY 
    return_rate_percentage DESC, 
    total_sales DESC
LIMIT 100;
