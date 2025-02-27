
WITH SalesData AS (
    SELECT 
        ws.warehouse_sk,
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        w.w_warehouse_name,
        d.d_date,
        d.d_weekday
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
SalesSummary AS (
    SELECT 
        warehouse_sk,
        web_site_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_sales_price) AS unique_sales_price_count
    FROM 
        SalesData
    GROUP BY 
        warehouse_sk, web_site_sk
),
RankedSales AS (
    SELECT 
        warehouse_sk,
        web_site_sk,
        total_sales,
        total_quantity,
        unique_sales_price_count,
        RANK() OVER (PARTITION BY warehouse_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    r.warehouse_sk,
    r.web_site_sk,
    r.total_sales,
    COALESCE(r.total_quantity, 0) AS total_quantity,
    CASE 
        WHEN r.unique_sales_price_count > 5 THEN 'High Variety'
        ELSE 'Low Variety' 
    END AS price_variety,
    d.d_weekday
FROM 
    RankedSales r
LEFT JOIN 
    date_dim d ON r.web_site_sk IN (SELECT DISTINCT ws.web_site_sk FROM web_sales ws)
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.warehouse_sk, r.total_sales DESC;
