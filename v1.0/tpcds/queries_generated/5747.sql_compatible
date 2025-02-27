
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND 
        dd.d_moy IN (6, 7)
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        r.total_sales
    FROM 
        warehouse w
    JOIN 
        RankedSales r ON w.w_warehouse_sk = r.web_site_sk
    WHERE 
        r.sales_rank <= 5
)
SELECT 
    tw.w_warehouse_id,
    tw.w_warehouse_name,
    tw.total_sales,
    CASE 
        WHEN tw.total_sales > 1000000 THEN 'High Performer'
        WHEN tw.total_sales BETWEEN 500000 AND 1000000 THEN 'Mid Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    TopWebsites tw
ORDER BY 
    tw.total_sales DESC;
