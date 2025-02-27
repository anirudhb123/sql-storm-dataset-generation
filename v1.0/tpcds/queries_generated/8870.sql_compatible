
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        total_orders, 
        avg_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id, 
    total_sales, 
    total_orders, 
    avg_profit 
FROM 
    TopWebSites 
WHERE 
    sales_rank <= 10
ORDER BY 
    total_sales DESC;
