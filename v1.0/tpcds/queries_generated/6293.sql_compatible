
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        d_year AS sales_year,
        d_month_seq AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, d_year, d_month_seq
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
store_metrics AS (
    SELECT 
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_store_transactions,
        AVG(ss_net_profit) AS avg_store_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_name
)
SELECT 
    ss.sales_year,
    ss.sales_month,
    ss.web_site_id,
    ss.total_sales,
    ss.total_orders,
    ss.avg_order_value,
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    sm.s_store_name,
    sm.total_store_sales,
    sm.total_store_transactions,
    sm.avg_store_profit
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON cs.total_customers > 0
JOIN 
    store_metrics sm ON sm.total_store_sales > 0
ORDER BY 
    ss.sales_year, ss.sales_month, ss.web_site_id;
