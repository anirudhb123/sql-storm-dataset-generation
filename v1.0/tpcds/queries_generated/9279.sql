
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        web_site_sk, 
        SUM(total_quantity) AS overall_quantity,
        SUM(total_sales) AS overall_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        web_site_sk
),
WebsiteDetails AS (
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        tw.overall_quantity,
        tw.overall_sales,
        w.w_state
    FROM 
        warehouse w
    JOIN 
        TopWebsites tw ON w.w_warehouse_sk = tw.web_site_sk
)
SELECT 
    wd.warehouse_id,
    wd.warehouse_name,
    wd.overall_quantity,
    wd.overall_sales,
    wd.w_state,
    CASE 
        WHEN wd.overall_sales > 100000 THEN 'High Performer'
        WHEN wd.overall_sales BETWEEN 50000 AND 100000 THEN 'Mid Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    WebsiteDetails wd
ORDER BY 
    wd.overall_sales DESC
LIMIT 20;
