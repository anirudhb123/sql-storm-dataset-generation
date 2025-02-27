
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        cd.cd_gender,
        ib.ib_income_band_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq IN (1, 2, 3) 
    GROUP BY 
        ws.web_site_sk, 
        cd.cd_gender, 
        ib.ib_income_band_sk
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_handled,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    ss.web_site_sk,
    ss.cd_gender,
    ss.ib_income_band_sk,
    ss.total_sales,
    ss.order_count,
    ws.orders_handled,
    ws.total_revenue
FROM 
    sales_summary ss
JOIN 
    warehouse_summary ws ON ss.web_site_sk = ws.w_warehouse_sk
ORDER BY 
    ss.total_sales DESC, 
    ws.total_revenue DESC;
