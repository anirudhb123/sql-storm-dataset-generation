
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss.ticket_number DESC) AS rn
    FROM store_sales ss
    WHERE ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ss.sold_date_sk, ss.item_sk
),
TotalSales AS (
    SELECT 
        cs.item_sk,
        SUM(cs.net_paid) AS total_catalog_sales
    FROM catalog_sales cs
    GROUP BY cs.item_sk
),
FilteredSales AS (
    SELECT 
        w.warehouse_name,
        COALESCE(SUM(s.total_sales), 0) AS warehouse_sales,
        COALESCE(t.total_catalog_sales, 0) AS total_catalog_sales
    FROM warehouse w
    LEFT JOIN SalesCTE s ON w.warehouse_sk = (SELECT inv.warehouse_sk 
                                               FROM inventory inv 
                                               WHERE inv.inv_date_sk = s.sold_date_sk AND inv.inv_item_sk = s.item_sk
                                               LIMIT 1)
    LEFT JOIN TotalSales t ON s.item_sk = t.item_sk
    GROUP BY w.warehouse_name
)
SELECT 
    f.warehouse_name,
    f.warehouse_sales,
    f.total_catalog_sales,
    CASE 
        WHEN f.warehouse_sales > f.total_catalog_sales THEN 'Warehouse Sales Exceed Catalog Sales' 
        ELSE 'Catalog Sales Exceed or Equal Warehouse Sales' 
    END AS sales_comparison,
    ROW_NUMBER() OVER (ORDER BY f.warehouse_sales DESC) AS sales_rank
FROM FilteredSales f
WHERE f.warehouse_sales IS NOT NULL
ORDER BY f.warehouse_sales DESC;
