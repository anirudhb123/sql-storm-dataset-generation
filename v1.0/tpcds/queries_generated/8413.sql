
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
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
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),

TopWebsites AS (
    SELECT 
        web_site_id, 
        total_quantity, 
        total_sales, 
        total_orders, 
        avg_sales_price,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM 
        SalesSummary
)

SELECT 
    w.web_site_id,
    w.web_name,
    tw.total_quantity,
    tw.total_sales,
    tw.total_orders,
    tw.avg_sales_price,
    tw.sales_rank
FROM 
    web_site w
JOIN 
    TopWebsites tw ON w.web_site_id = tw.web_site_id
WHERE 
    tw.sales_rank <= 10
ORDER BY 
    tw.sales_rank;
