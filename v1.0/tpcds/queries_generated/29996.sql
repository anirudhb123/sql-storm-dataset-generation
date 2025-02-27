
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        wsorder_number,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_country = 'USA'
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        web_site_sk,
        MAX(total_sales) AS max_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    w.web_site_id,
    w.web_name,
    ts.max_sales,
    COUNT(ws.ws_order_number) AS number_of_orders
FROM 
    TopSales ts
JOIN 
    web_site w ON ts.web_site_sk = w.web_site_sk
JOIN 
    web_sales ws ON w.web_site_sk = ws.ws_web_site_sk
GROUP BY 
    w.web_site_id, w.web_name, ts.max_sales
ORDER BY 
    ts.max_sales DESC;
