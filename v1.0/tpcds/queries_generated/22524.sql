
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales_price = 1
),
SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
),
InventoryStats AS (
    SELECT 
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        AVG(i.inv_quantity_on_hand) AS avg_quantity
    FROM 
        inventory i
    GROUP BY 
        i.inv_item_sk
),
DetailedSales AS (
    SELECT 
        coalesce(ws.ws_item_sk, cs.cs_item_sk) AS item_sk,
        COALESCE(ws.ws_sales_price, 0) AS web_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COALESCE(cs.catalog_order_count, 0) AS catalog_order_count,
        COALESCE(inv.total_quantity, 0) AS stock_on_hand,
        COALESCE(inv.avg_quantity, 0) AS avg_stock
    FROM 
        web_sales ws
    FULL OUTER JOIN SalesData cs ON ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN InventoryStats inv ON coalesce(ws.ws_item_sk, cs.cs_item_sk) = inv.inv_item_sk
    GROUP BY 
        ws.ws_item_sk, cs.cs_item_sk, inv.total_quantity, inv.avg_quantity
)
SELECT 
    ds.item_sk,
    ds.web_sales_price,
    ds.web_order_count,
    ds.catalog_order_count,
    ds.stock_on_hand,
    ds.avg_stock,
    CASE 
        WHEN ds.web_order_count = 0 AND ds.catalog_order_count = 0 THEN 'No Sales'
        WHEN ds.web_sales_price > (SELECT AVG(web_sales_price) FROM DetailedSales) THEN 'High Demand'
        ELSE 'Standard'
    END AS Sales_Category
FROM 
    DetailedSales ds
WHERE 
    ds.stock_on_hand > (SELECT AVG(stock_on_hand) FROM DetailedSales) OR ds.web_sales_price IS NULL
ORDER BY 
    ds.item_sk, ds.web_sales_price DESC;
