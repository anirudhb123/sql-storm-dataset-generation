
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    GROUP BY 
        ws.web_site_id, d.d_year, d.d_month_seq
),
warehouse_data AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_quantity,
    sd.total_sales,
    wd.w_warehouse_id,
    wd.unique_items,
    wd.total_profit
FROM 
    sales_data sd
JOIN 
    warehouse_data wd ON sd.d_year = wd.warehouse_id
WHERE 
    sd.total_sales > 5000
ORDER BY 
    sd.total_sales DESC, wd.total_profit DESC
LIMIT 100;
