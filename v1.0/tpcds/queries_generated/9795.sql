
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        wd.d_year AS sales_year,
        wd.d_month_seq AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    GROUP BY 
        ws.web_site_sk, wd.d_year, wd.d_month_seq
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS estimated_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
    FROM 
        warehouse w
    LEFT JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN 
        store_returns sr ON w.w_warehouse_sk = sr.sr_store_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    ss.web_site_sk,
    ss.sales_year,
    ss.sales_month,
    ss.total_quantity,
    ss.total_sales,
    ss.total_profit,
    ss.total_orders,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.estimated_purchase,
    wp.w_warehouse_sk,
    wp.total_inventory,
    wp.total_returns
FROM 
    sales_summary ss
JOIN 
    demographic_summary ds ON ss.web_site_sk % 2 = ds.customer_count % 2
JOIN 
    warehouse_performance wp ON ss.web_site_sk % 3 = wp.w_warehouse_sk % 3
ORDER BY 
    ss.sales_year, ss.sales_month, ss.total_profit DESC;
