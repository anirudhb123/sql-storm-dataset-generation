
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND 
        p.p_discount_active = 'Y'
    GROUP BY 
        ws.web_site_id, 
        ws.ws_order_number
),
TopSites AS (
    SELECT 
        web_site_id, 
        total_quantity, 
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    ts.web_site_id,
    ts.total_quantity,
    ts.total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ts.total_sales) AS avg_sales_per_order
FROM 
    TopSites ts
JOIN 
    web_sales ws ON ts.web_site_id = ws.ws_web_site_sk
GROUP BY 
    ts.web_site_id, 
    ts.total_quantity, 
    ts.total_sales
ORDER BY 
    ts.total_sales DESC;
