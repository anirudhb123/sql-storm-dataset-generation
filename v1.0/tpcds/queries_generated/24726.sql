
WITH RankedSales AS (
    SELECT 
        ss_item_sk, 
        ss_store_sk,
        ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sales_price DESC) as rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
HighSales AS (
    SELECT 
        rs.ss_item_sk,
        rs.ss_store_sk,
        rs.ss_sales_price,
        COALESCE(SUM(cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales
    FROM 
        RankedSales rs
    LEFT JOIN catalog_sales cs ON rs.ss_item_sk = cs.cs_item_sk
        AND cs.cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    LEFT JOIN web_sales ws ON rs.ss_item_sk = ws.ws_item_sk
        AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    WHERE 
        rs.rank = 1
    GROUP BY 
        rs.ss_item_sk, 
        rs.ss_store_sk, 
        rs.ss_sales_price
),
SalesComparison AS (
    SELECT 
        hs.ss_item_sk,
        hs.ss_store_sk,
        hs.ss_sales_price,
        (hs.total_catalog_sales + hs.total_web_sales) AS total_sales,
        CASE 
            WHEN hs.total_catalog_sales > hs.total_web_sales THEN 'Catalog'
            WHEN hs.total_catalog_sales < hs.total_web_sales THEN 'Web'
            ELSE 'Equal'
        END AS sales_dominance
    FROM 
        HighSales hs
)
SELECT 
    sc.ss_item_sk,
    sc.ss_store_sk,
    sc.ss_sales_price,
    sc.total_sales,
    sc.sales_dominance,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_customer_sk IN (SELECT DISTINCT ss_customer_sk FROM store_sales WHERE ss_item_sk = sc.ss_item_sk)) AS unique_customers
FROM 
    SalesComparison sc
ORDER BY 
    total_sales DESC, 
    sc.ss_sales_price DESC
LIMIT 10;
