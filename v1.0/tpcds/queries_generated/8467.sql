
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.web_site_id
), top_web_sites AS (
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
    ws.web_site_id,
    ws.web_name,
    t.total_sales,
    t.order_count,
    ROUND((t.total_sales / NULLIF(t.order_count, 0)), 2) AS avg_order_value,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales
FROM 
    top_web_sites t
JOIN 
    web_site ws ON t.web_site_id = ws.web_site_id
LEFT JOIN 
    catalog_sales cs ON cs.cs_bill_customer_sk IN (
        SELECT c_customer_sk FROM customer WHERE c_current_cdemo_sk IN 
        (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'F')
    )
JOIN 
    warehouse w ON ws.web_site_id = w.w_warehouse_id
GROUP BY 
    ws.web_site_id, ws.web_name, t.total_sales, t.order_count, w.w_warehouse_name, w.w_city, w.w_state
ORDER BY 
    t.total_sales DESC;
