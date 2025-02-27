
WITH sales_data AS (
    SELECT 
        ws_ws.web_site_sk,
        ws.ws_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        db.d_year,
        db.d_month_seq,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS row_num
    FROM 
        web_sales ws
    JOIN 
        customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
    JOIN 
        customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim db ON ws.ws_sold_date_sk = db.d_date_sk
    WHERE 
        db.d_year = 2023
        AND ws.ws_sales_price > 100.00
),
aggregated_sales AS (
    SELECT 
        web_site_sk,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        AVG(ws_sales_price) AS avg_sale_price,
        MAX(ws_sales_price) AS max_sale_price,
        MIN(ws_sales_price) AS min_sale_price,
        STRING_AGG(DISTINCT cd_gender) AS distinct_genders,
        STRING_AGG(DISTINCT cd_marital_status) AS distinct_marital_status 
    FROM 
        sales_data
    WHERE 
        row_num <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    w.w_warehouse_id,
    ag.total_sales,
    ag.total_revenue,
    ag.avg_sale_price,
    ag.max_sale_price,
    ag.min_sale_price,
    ag.distinct_genders,
    ag.distinct_marital_status
FROM 
    aggregated_sales ag
JOIN 
    warehouse w ON ag.web_site_sk = w.w_warehouse_sk
ORDER BY 
    ag.total_revenue DESC
LIMIT 10;
