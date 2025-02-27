
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id, 
        d.d_year
),
RankedSales AS (
    SELECT 
        web_site_id,
        d_year,
        total_sales,
        order_count,
        avg_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id,
    r.d_year,
    r.total_sales,
    r.order_count,
    r.avg_profit
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.d_year, 
    r.total_sales DESC;
