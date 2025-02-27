
WITH RecursiveSalesCTE AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_order_number
    UNION ALL
    SELECT 
        csr.cs_order_number,
        SUM(csr.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT csr.cs_item_sk) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY csr.cs_order_number ORDER BY SUM(csr.cs_ext_sales_price) DESC)
    FROM 
        catalog_sales csr
    JOIN 
        date_dim dd ON csr.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        csr.cs_order_number
),
AggregatedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(rs.total_sales) AS total_sales,
        COUNT(DISTINCT rs.total_items) AS unique_items
    FROM 
        RecursiveSalesCTE rs
    JOIN 
        web_site ws ON ws.web_site_sk = rs.ws_order_number
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    ws.web_name,
    COALESCE(as.total_sales, 0) AS total_sales,
    COALESCE(as.unique_items, 0) AS unique_items,
    CONCAT('Sales: $', FORMAT(COALESCE(as.total_sales, 0), 2)) AS sales_string,
    CASE 
        WHEN COALESCE(as.total_sales, 0) > 100000 THEN 'High Performer'
        WHEN COALESCE(as.total_sales, 0) > 50000 THEN 'Mid Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    web_site ws
LEFT JOIN 
    AggregatedSales as ON ws.web_site_sk = as.web_site_sk
WHERE 
    ws.web_gmt_offset IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 10;
