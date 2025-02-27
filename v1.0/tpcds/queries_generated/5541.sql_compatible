
WITH sales_performance AS (
    SELECT 
        s.s_store_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_net_profit) AS avg_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND dd.d_year = 2023
        AND ws.ws_net_paid > 0
    GROUP BY 
        s.s_store_id
),
demographic_analysis AS (
    SELECT 
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        SUM(sp.total_revenue) AS total_revenue_from_customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        sales_performance sp ON c.c_customer_sk = sp.s_store_id
    GROUP BY 
        cd.cd_education_status
)
SELECT 
    da.cd_education_status,
    da.total_customers,
    da.total_revenue_from_customers,
    (da.total_revenue_from_customers / NULLIF(da.total_customers, 0)) AS avg_revenue_per_customer
FROM 
    demographic_analysis da
ORDER BY 
    avg_revenue_per_customer DESC;
