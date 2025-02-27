
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
top_web_sites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tws.web_site_id,
    tws.total_sales,
    tws.order_count,
    (SELECT COUNT(DISTINCT ws_item_sk) FROM web_sales WHERE ws_web_site_sk IN (SELECT web_site_sk FROM web_site WHERE web_site_id = tws.web_site_id)) AS total_items_sold
FROM 
    top_web_sites tws
ORDER BY 
    tws.total_sales DESC;
