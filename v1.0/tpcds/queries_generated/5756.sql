
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.web_site_id, d.d_year
),
customer_data AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales_value
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_quantity,
    sd.total_net_paid,
    sd.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_count,
    ws.w_warehouse_id,
    ws.total_sales_value
FROM 
    sales_data AS sd
JOIN 
    customer_data AS cd ON cd.customer_count > 1000
JOIN 
    warehouse_sales AS ws ON ws.total_sales_value > 100000
ORDER BY 
    sd.total_net_paid DESC, cd.customer_count DESC;
