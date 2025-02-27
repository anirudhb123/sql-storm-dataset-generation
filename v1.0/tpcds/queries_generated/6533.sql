
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        DATE_TRUNC('month', dd.d_date) AS sale_month
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2022 AND 
        cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_sk, sale_month
),
RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY web_site_sk ORDER BY total_net_profit DESC) AS rank
    FROM 
        SalesData
)
SELECT 
    s.web_site_sk,
    s.sale_month,
    s.total_net_profit,
    s.total_orders,
    s.avg_sales_price,
    s.unique_customers
FROM 
    RankedSales s
WHERE 
    s.rank <= 5
ORDER BY 
    s.web_site_sk, s.sale_month;
