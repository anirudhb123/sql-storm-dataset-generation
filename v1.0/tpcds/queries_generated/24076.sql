
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
HighValueItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        RankedSales
    WHERE 
        rn = 1
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_sales_price * ws_quantity) > (SELECT AVG(ws_sales_price * ws_quantity) FROM web_sales)
),
WarehouseInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
SalesAndInventory AS (
    SELECT 
        hvi.ws_item_sk,
        hvi.total_sales,
        wi.total_quantity,
        (hvi.total_sales / NULLIF(wi.total_quantity, 0)) AS sales_per_item
    FROM 
        HighValueItems hvi
    LEFT JOIN 
        WarehouseInventory wi ON hvi.ws_item_sk = wi.inv_item_sk
)
SELECT 
    si.ws_item_sk,
    si.total_sales,
    si.total_quantity,
    COALESCE(si.sales_per_item, 0) AS sales_per_item,
    CASE 
        WHEN si.total_quantity IS NULL OR si.total_quantity = 0 THEN 'Inventory Not Available'
        WHEN si.sales_per_item > 20 THEN 'High Sales Efficiency'
        ELSE 'Regular Sales Efficiency'
    END AS sales_efficiency
FROM 
    SalesAndInventory si
WHERE 
    EXISTS (
        SELECT 1 
        FROM customer AS c
        WHERE c.c_customer_sk IN (
            SELECT DISTINCT sr_customer_sk 
            FROM store_returns 
            WHERE sr_item_sk = si.ws_item_sk
        )
    )
ORDER BY 
    si.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
