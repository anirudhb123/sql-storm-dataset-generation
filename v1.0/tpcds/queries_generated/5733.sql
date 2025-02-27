
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
), top_web_sites AS (
    SELECT 
        sales_summary.web_site_id,
        sales_summary.total_quantity_sold,
        sales_summary.total_sales,
        sales_summary.total_orders,
        sales_summary.average_profit,
        RANK() OVER (ORDER BY sales_summary.total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)

SELECT 
    w.web_site_name,
    t.total_quantity_sold,
    t.total_sales,
    t.total_orders,
    t.average_profit
FROM 
    top_web_sites t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
