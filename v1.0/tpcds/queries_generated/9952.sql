
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.w_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.ws_sold_date_sk
),
TopSales AS (
    SELECT 
        web_site_id, 
        total_quantity, 
        total_net_paid 
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 5
)
SELECT 
    wsp.wp_url,
    wsp.wp_type,
    ts.total_quantity,
    ts.total_net_paid
FROM 
    web_page wsp
JOIN 
    TopSales ts ON wsp.wp_web_page_sk = ts.web_site_id
ORDER BY 
    ts.total_net_paid DESC;
