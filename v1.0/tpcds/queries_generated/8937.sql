
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
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
    AND 
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
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        RANK() OVER (ORDER BY avg_profit DESC) AS profit_rank
    FROM 
        SalesSummary
)
SELECT 
    w.web_site_id,
    w.web_name,
    tw.total_sales,
    tw.total_orders,
    tw.avg_profit,
    tw.sales_rank,
    tw.profit_rank
FROM 
    web_site w
JOIN 
    TopWebSites tw ON w.web_site_id = tw.web_site_id
WHERE 
    tw.sales_rank <= 5 OR tw.profit_rank <= 5
ORDER BY 
    tw.sales_rank, tw.profit_rank;
