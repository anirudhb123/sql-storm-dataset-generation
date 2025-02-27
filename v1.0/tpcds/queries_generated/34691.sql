
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_paid) AS TotalNetSales,
        1 AS Level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) + TotalNetSales,
        Level + 1
    FROM 
        store_sales
    JOIN 
        SalesCTE ON store_sales.ss_store_sk = SalesCTE.ss_store_sk
    WHERE 
        Level < 5
    GROUP BY 
        ss_store_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS TotalWebSales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
),
StoreInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS TotalInventory
    FROM 
        inventory inv
    JOIN 
        item it ON inv.inv_item_sk = it.i_item_sk
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    it.i_item_id,
    it.i_product_name,
    COALESCE(ws.TotalWebSales, 0) AS TotalWebSales,
    COALESCE(SALESCTE.TotalNetSales, 0) AS TotalStoreSales,
    COALESCE(inventory.TotalInventory, 0) AS TotalInventory,
    CASE 
        WHEN COALESCE(ws.TotalWebSales, 0) > 0 THEN 'Available for Web'
        ELSE 'Not Available for Web' 
    END AS AvailabilityStatus,
    ROW_NUMBER() OVER (PARTITION BY it.i_item_sk ORDER BY COALESCE(ws.TotalWebSales, 0) DESC) AS Rank
FROM 
    item it
LEFT JOIN 
    ItemSales ws ON it.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    SalesCTE ON it.i_item_sk IN (SELECT ss_item_sk FROM store_sales)
LEFT JOIN 
    StoreInventory inventory ON it.i_item_sk = inventory.inv_item_sk
WHERE 
    (COALESCE(ws.TotalWebSales, 0) > 0 OR COALESCE(SALESCTE.TotalNetSales, 0) > 0) 
    AND it.i_current_price BETWEEN 10 AND 100
ORDER BY 
    TotalStoreSales DESC, 
    TotalWebSales DESC;
