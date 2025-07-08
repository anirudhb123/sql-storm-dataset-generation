
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        sm.sm_type AS shipping_method,
        dd.d_year AS sales_year
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_item_sk, sm.sm_type, dd.d_year
),
customer_segment AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity_sold,
    sd.total_sales,
    sd.total_discount,
    cs.customer_count,
    cs.avg_purchase_estimate,
    sd.shipping_method,
    sd.sales_year
FROM 
    sales_data sd
LEFT JOIN 
    customer_segment cs ON cs.cd_demo_sk = (sd.ws_item_sk % 100)
WHERE 
    sd.total_sales > 1000
ORDER BY 
    sd.sales_year, sd.total_sales DESC
LIMIT 100;
