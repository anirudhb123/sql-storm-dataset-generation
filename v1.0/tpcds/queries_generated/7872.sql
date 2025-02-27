
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_paid) AS total_sales,
        AVG(ws.net_profit) AS avg_profit,
        SUM(ws.quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.w_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        w.w_warehouse_name, d.d_year
), customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_estimated_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IN ('High', 'Medium')
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.w_warehouse_name,
    ss.d_year,
    ss.total_orders,
    ss.total_sales,
    ss.avg_profit,
    ss.total_quantity_sold,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_customers,
    cs.total_estimated_purchases
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.total_orders > 5
ORDER BY 
    ss.total_sales DESC, cs.total_customers DESC
FETCH FIRST 100 ROWS ONLY;
