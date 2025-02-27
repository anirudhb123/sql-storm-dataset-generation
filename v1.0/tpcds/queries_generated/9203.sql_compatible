
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
top_websites AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales,
        average_sales_price,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tw.web_site_id,
    tw.total_quantity,
    tw.total_sales,
    tw.average_sales_price,
    tw.total_orders,
    tw.sales_rank,
    COUNT(*) OVER () AS total_websites
FROM 
    top_websites tw
WHERE 
    tw.sales_rank <= 10
ORDER BY 
    tw.sales_rank;
