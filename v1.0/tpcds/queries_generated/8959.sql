
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_ext_sales_price) AS avg_sales_price,
        DATE_FORMAT(d.d_date, '%Y-%m') AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id, sales_month
),
RankedSales AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders,
        avg_sales_price,
        sales_month,
        RANK() OVER (PARTITION BY sales_month ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id,
    sales_month,
    total_net_profit,
    total_orders,
    avg_sales_price
FROM 
    RankedSales
WHERE 
    profit_rank <= 5
ORDER BY 
    sales_month, total_net_profit DESC;
