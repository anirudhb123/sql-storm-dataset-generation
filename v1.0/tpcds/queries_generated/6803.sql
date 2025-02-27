
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq IN (1, 2, 3)  -- First quarter
    GROUP BY 
        ws.web_site_id
),
average_sales AS (
    SELECT 
        web_site_id,
        AVG(total_revenue) AS avg_revenue,
        AVG(total_orders) AS avg_orders,
        AVG(unique_customers) AS avg_unique_customers,
        AVG(total_items_sold) AS avg_items_sold
    FROM 
        sales_summary
    GROUP BY 
        web_site_id
),
demographic_performance AS (
    SELECT 
        cd.gender,
        AVG(as.avg_revenue) AS avg_revenue,
        AVG(as.avg_orders) AS avg_orders,
        AVG(as.avg_unique_customers) AS avg_unique_customers,
        AVG(as.avg_items_sold) AS avg_items_sold
    FROM 
        average_sales as
    JOIN 
        customer c ON as.web_site_id = c.c_customer_id -- Assuming c_customer_id relates to web site
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.gender
)
SELECT 
    dp.gender,
    dp.avg_revenue,
    dp.avg_orders,
    dp.avg_unique_customers,
    dp.avg_items_sold
FROM 
    demographic_performance dp
ORDER BY 
    dp.gender;
