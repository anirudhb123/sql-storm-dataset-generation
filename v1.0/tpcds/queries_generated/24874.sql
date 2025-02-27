
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS RankedPrice
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.RankedPrice <= 3
),
CombinedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS TotalCatalogQuantity,
        SUM(cs.cs_net_profit) AS TotalCatalogProfit
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
),
SalesSummary AS (
    SELECT 
        fs.ws_item_sk,
        SUM(fs.ws_quantity) AS TotalWebQuantity,
        SUM(fs.ws_sales_price * fs.ws_quantity) AS TotalWebSales,
        COALESCE(cs.TotalCatalogQuantity, 0) AS TotalCatalogQuantity,
        COALESCE(cs.TotalCatalogProfit, 0) AS TotalCatalogProfit
    FROM 
        FilteredSales fs
    LEFT JOIN 
        CombinedSales cs ON fs.ws_item_sk = cs.cs_item_sk
    GROUP BY 
        fs.ws_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.TotalWebQuantity,
    ss.TotalWebSales,
    ss.TotalCatalogQuantity,
    ss.TotalCatalogProfit,
    CASE 
        WHEN ss.TotalWebSales > ss.TotalCatalogProfit THEN 'Web Sales Surpass Catalog'
        WHEN ss.TotalWebSales < ss.TotalCatalogProfit THEN 'Catalog Sales Surpass Web'
        ELSE 'Equal Sales'
    END AS SalesComparison,
    CASE 
        WHEN ss.TotalWebQuantity IS NULL OR ss.TotalCatalogQuantity IS NULL THEN 'Missing Data Alert'
        WHEN ss.TotalWebQuantity = 0 AND ss.TotalCatalogQuantity = 0 THEN 'No Sales Activity'
        ELSE 'Sales Data Available'
    END AS SalesActivityStatus,
    NULLIF(ss.TotalWebSales, 0) / NULLIF(ss.TotalCatalogProfit, 0) AS SalesRatio
FROM 
    SalesSummary ss
WHERE 
    ss.TotalWebQuantity > 0 OR ss.TotalCatalogQuantity > 0
ORDER BY 
    ss.TotalWebSales DESC, ss.TotalCatalogProfit DESC
LIMIT 100;
