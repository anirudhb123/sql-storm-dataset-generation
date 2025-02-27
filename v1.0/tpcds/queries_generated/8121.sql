
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales
    FROM 
        RankedSales
    WHERE 
        rank <= 5
    GROUP BY 
        web_site_sk
)
SELECT 
    w.web_site_id,
    w.web_name,
    w.web_country,
    tw.total_quantity,
    tw.total_sales,
    (tw.total_sales - tw.total_quantity * 0.1) AS net_profit_estimation
FROM 
    TopWebsites tw
JOIN 
    web_site w ON tw.web_site_sk = w.web_site_sk
ORDER BY 
    tw.total_sales DESC;
