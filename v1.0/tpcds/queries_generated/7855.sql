
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tw.web_site_id,
    tw.total_sales,
    tw.order_count,
    COUNT(DISTINCT wr.wr_order_number) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount
FROM 
    TopWebsites tw
LEFT JOIN 
    web_returns wr ON tw.web_site_id = wr.wr_web_page_sk
GROUP BY 
    tw.web_site_id, tw.total_sales, tw.order_count
ORDER BY 
    tw.total_sales DESC;
