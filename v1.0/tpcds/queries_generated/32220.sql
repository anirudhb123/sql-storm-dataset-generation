
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_sales_price,
        ss_quantity,
        1 AS level,
        ss_net_profit
    FROM 
        store_sales
    WHERE 
        ss_item_sk IS NOT NULL

    UNION ALL

    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_sales_price + (ss_sales_price * 0.1 * level) AS ss_sales_price,
        ss_quantity * 1.05 AS ss_quantity,
        level + 1,
        ss_net_profit + (ss_net_profit * 0.1)
    FROM 
        SalesCTE
    WHERE 
        level < 5
),
HighSales AS (
    SELECT 
        s_store_sk, 
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk
),
LowSales AS (
    SELECT 
        s_store_sk, 
        SUM(cs_ext_sales_price) AS total_catalog_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk
),
FilteredSales AS (
    SELECT 
        hs.s_store_sk,
        hs.total_sales,
        ls.total_catalog_sales
    FROM 
        HighSales hs 
    LEFT JOIN 
        LowSales ls ON hs.s_store_sk = ls.s_store_sk
    WHERE 
        hs.total_sales > 100000 AND (ls.total_catalog_sales IS NULL OR ls.total_catalog_sales < 5000)
)
SELECT 
    f.s_store_sk,
    COALESCE(f.total_catalog_sales, 0) AS total_catalog_sales,
    SUM(s.sales_price) AS adjusted_sales_price,
    SUM(s.ss_net_profit) AS total_net_profit
FROM 
    FilteredSales f
JOIN 
    SalesCTE s ON f.s_store_sk = s.ss_store_sk
GROUP BY 
    f.s_store_sk, f.total_catalog_sales
ORDER BY 
    total_net_profit DESC
LIMIT 10;
