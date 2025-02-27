
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
),
SalesReport AS (
    SELECT 
        DATE_FORMAT(dd.d_date, '%Y-%m') AS sale_month,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        sale_month
),
StorePerformance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE 
        ss.ss_sold_date_sk IS NOT NULL
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_web_sales,
    cs.total_spent,
    sr.sale_month,
    sr.total_revenue,
    sr.total_orders,
    sr.avg_order_value,
    sp.total_store_sales,
    sp.total_store_orders
FROM 
    CustomerSummary cs
JOIN 
    SalesReport sr ON cs.total_spent > 1000  -- joining based on a threshold for spending
LEFT JOIN 
    StorePerformance sp ON sp.total_store_sales > 5000;  -- Filtering for significant store performance
