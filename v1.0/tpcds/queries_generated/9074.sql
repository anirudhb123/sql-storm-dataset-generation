
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
customer_segments AS (
    SELECT 
        cd.gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ss.total_quantity) AS segment_sales_quantity,
        SUM(ss.total_revenue) AS segment_sales_revenue
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ss ON ss.web_site_sk IN (
            SELECT w.web_site_sk 
            FROM web_site w 
            WHERE w.web_country = 'USA'
        )
    GROUP BY 
        cd.gender
)
SELECT 
    cs.gender,
    cs.customer_count,
    cs.segment_sales_quantity,
    cs.segment_sales_revenue,
    cs.segment_sales_revenue / NULLIF(cs.segment_sales_quantity, 0) AS avg_revenue_per_item
FROM 
    customer_segments cs
ORDER BY 
    cs.segment_sales_revenue DESC
LIMIT 10;
