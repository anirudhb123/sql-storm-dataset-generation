
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE 
        cd.cd_gender = 'F'
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
        AND i.i_current_price > 20
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
),
top_sales AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales
    FROM 
        ranked_sales 
    WHERE 
        sales_rank <= 10
)
SELECT 
    ts.web_site_id,
    ts.total_quantity,
    ts.total_sales,
    AVG(ts.total_sales) OVER () AS avg_sales,
    COUNT(ts.total_sales) OVER () AS total_count
FROM 
    top_sales ts
ORDER BY 
    ts.total_sales DESC;
