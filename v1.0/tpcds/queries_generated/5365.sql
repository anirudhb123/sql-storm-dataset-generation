
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        AVG(ws.net_paid_inc_ship_tax) AS avg_order_value,
        COUNT(DISTINCT ws.bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
TopSites AS (
    SELECT 
        web_site_id, 
        total_orders, 
        total_profit, 
        avg_order_value, 
        unique_customers,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS site_rank
    FROM 
        SalesData
)
SELECT 
    ts.web_site_id,
    ts.total_orders,
    ts.total_profit,
    ts.avg_order_value,
    ts.unique_customers
FROM 
    TopSites ts
WHERE 
    ts.site_rank <= 5
ORDER BY 
    ts.total_profit DESC;
