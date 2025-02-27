
WITH sales_data AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        SUM(ws_ext_ship_cost) AS total_shipping,
        ws_ship_mode_sk,
        w_city,
        w_state
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_ship_mode_sk, w_city, w_state
),
ranked_sales AS (
    SELECT 
        total_sales,
        total_tax,
        total_shipping,
        ws_ship_mode_sk,
        w_city,
        w_state,
        RANK() OVER (PARTITION BY w_state ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    r.city AS shipping_city,
    r.state AS shipping_state,
    r.ws_ship_mode_sk,
    r.total_sales,
    r.total_tax,
    r.total_shipping
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.shipping_state,
    r.total_sales DESC;
