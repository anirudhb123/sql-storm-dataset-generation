
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
HighReturns AS (
    SELECT 
        rr.sr_item_sk,
        i.i_item_desc,
        rr.total_return_quantity
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.return_rank = 1
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
SalesComparison AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price * cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price * ss.ss_quantity), 0) AS total_store_sales
    FROM 
        item i 
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk 
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk 
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk 
    GROUP BY 
        i.i_item_id
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    hc.total_quantity_on_hand,
    sc.total_web_sales,
    sc.total_catalog_sales,
    sc.total_store_sales,
    CASE 
        WHEN hc.total_quantity_on_hand IS NULL THEN 'Out of Stock' 
        WHEN hc.total_quantity_on_hand < 10 THEN 'Low Stock' 
        ELSE 'In Stock' 
    END AS stock_status,
    CASE 
        WHEN sc.total_web_sales >= (SELECT AVG(total_web_sales) FROM SalesComparison) 
             AND sc.total_catalog_sales >= (SELECT AVG(total_catalog_sales) FROM SalesComparison) 
        THEN 'High Sales' 
        ELSE 'Regular Sales' 
    END AS sales_category
FROM 
    HighReturns hr
JOIN 
    InventoryCheck hc ON hr.sr_item_sk = hc.inv_item_sk
JOIN 
    SalesComparison sc ON hr.sr_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = hr.sr_item_sk)
ORDER BY 
    hr.total_return_quantity DESC, 
    sc.total_web_sales DESC;
