
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS order_count,
        AVG(ws.net_paid) AS avg_order_value,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
customer_data AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.order_count,
    sd.avg_order_value,
    cd.unique_customers
FROM 
    sales_data sd
LEFT JOIN 
    customer_data cd ON sd.sales_rank = cd.cd_demo_sk
WHERE 
    sd.total_sales > 10000
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
