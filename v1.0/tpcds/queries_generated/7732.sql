
WITH RankedSales AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY SUM(ws.ws_quantity) DESC) AS quantity_rank,
        RANK() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_web_page_sk
),
TopSales AS (
    SELECT 
        ws.ws_web_page_sk,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        quantity_rank <= 10 OR sales_rank <= 10
)
SELECT 
    wp.wp_url,
    ts.total_quantity,
    ts.total_sales,
    ROUND(ts.total_sales / NULLIF(ts.total_quantity, 0), 2) AS avg_sales_price_per_item
FROM 
    TopSales ts
JOIN 
    web_page wp ON ts.ws_web_page_sk = wp.wp_web_page_sk
ORDER BY 
    ts.total_sales DESC;
