
WITH sales_data AS (
    SELECT 
        ws.web_site_id, 
        w.warehouse_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws 
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws.web_site_id, w.warehouse_id
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender, 
        cd.cd_marital_status, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    sd.web_site_id,
    sd.warehouse_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(cd.c_customer_id) AS customer_count,
    SUM(sd.total_sales) AS total_sales,
    SUM(cd.total_orders) AS total_orders
FROM 
    sales_data sd
JOIN 
    customer_data cd ON sd.total_orders > 0
GROUP BY 
    sd.web_site_id, sd.warehouse_id, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales DESC, customer_count DESC;
