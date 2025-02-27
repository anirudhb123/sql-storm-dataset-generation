
WITH RECURSIVE sales_data AS (
    SELECT 
        d.d_date,
        ws.ws_sales_price,
        ws.ws_quantity,
        wc.wc_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY d.d_date DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        item wc ON ws.ws_item_sk = wc.i_item_sk
    WHERE 
        ws.ws_sales_price > 1.00
        AND COALESCE(ws.ws_quantity, 0) > 0
        AND d.d_year = 2023
    UNION ALL
    SELECT 
        d.d_date,
        cs.cs_sales_price,
        cs.cs_quantity,
        c.cs_item_sk,
        cs.cs_order_number,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY d.d_date DESC) AS rnk
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN 
        item c ON cs.cs_item_sk = c.i_item_sk
    WHERE 
        cs.cs_sales_price > 1.00
        AND COALESCE(cs.cs_quantity, 0) > 0
        AND d.d_year = 2023
),
aggregated_sales AS (
    SELECT
        d.d_date,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        sales_data d
    LEFT JOIN 
        web_sales ws ON d.ws_order_number = ws.ws_order_number
    LEFT JOIN 
        catalog_sales cs ON d.ws_order_number = cs.cs_order_number
    WHERE 
        d.rnk = 1
    GROUP BY 
        d.d_date
)
SELECT
    a.d_date,
    a.total_web_sales,
    a.total_catalog_sales,
    COALESCE(a.total_web_sales, 0) - COALESCE(a.total_catalog_sales, 0) AS sales_difference,
    CASE 
        WHEN a.total_web_sales IS NULL THEN 'No Web Sales'
        WHEN a.total_catalog_sales IS NULL THEN 'No Catalog Sales'
        ELSE 'Both Sales Present'
    END AS sales_status
FROM 
    aggregated_sales a
FULL OUTER JOIN 
    (SELECT 
        DISTINCT d.d_date 
     FROM 
        date_dim d
     WHERE 
        d.d_year = 2023) d ON a.d_date = d.d_date
WHERE 
    (a.total_web_sales IS NOT NULL OR a.total_catalog_sales IS NOT NULL)
ORDER BY 
    a.d_date DESC NULLS LAST;
