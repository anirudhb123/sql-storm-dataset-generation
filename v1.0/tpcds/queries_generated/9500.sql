
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND 
        dd.d_month_seq IN (1, 2, 3) -- First quarter of 2022
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        SUM(total_sales) AS total_quarter_sales,
        SUM(total_orders) AS total_quarter_orders
    FROM 
        RankedSales
    WHERE 
        rank_sales <= 5
    GROUP BY 
        web_site_sk
)
SELECT 
    w.web_site_id,
    w.web_name,
    tw.total_quarter_sales,
    tw.total_quarter_orders,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders_from_web
FROM 
    TopWebsites tw
JOIN 
    web_site w ON tw.web_site_sk = w.web_site_sk
JOIN 
    web_sales ws ON ws.ws_web_site_sk = w.web_site_sk
WHERE 
    ws.ws_sold_date_sk IN (SELECT ws_sold_date_sk FROM web_sales) -- Ensuring linked sales
GROUP BY 
    w.web_site_id, w.web_name, tw.total_quarter_sales, tw.total_quarter_orders
ORDER BY 
    tw.total_quarter_sales DESC;
