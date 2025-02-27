
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.web_site_sk
),
top_sales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_sales,
        wd.wd_warehouse_name,
        sm.sm_type,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        ranked_sales rs
    JOIN 
        warehouse wd ON rs.ws_item_sk = wd.w_warehouse_sk 
    JOIN 
        ship_mode sm ON rs.ws_item_sk = sm.sm_ship_mode_sk 
    JOIN 
        customer_demographics cd ON rs.ws_item_sk = cd.cd_demo_sk 
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ts.ws_item_sk,
    ts.total_sales,
    ts.wd_warehouse_name,
    ts.sm_type,
    COUNT(ts.cd_gender) AS gender_count,
    COUNT(ts.cd_marital_status) AS marital_status_count
FROM 
    top_sales ts
GROUP BY 
    ts.ws_item_sk, 
    ts.total_sales, 
    ts.wd_warehouse_name, 
    ts.sm_type
ORDER BY 
    ts.total_sales DESC;
