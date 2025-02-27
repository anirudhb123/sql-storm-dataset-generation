
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'S'
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count,
        average_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    tw.web_site_id,
    tw.total_sales,
    tw.order_count,
    tw.average_profit
FROM 
    TopWebsites tw
WHERE 
    tw.sales_rank <= 10
ORDER BY 
    tw.total_sales DESC;
