
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.net_profit) AS total_profit, 
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_paid_inc_tax) AS avg_order_value,
        w.warehouse_name,
        c.c_city,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN 
        date_dim d ON ws.sold_date_sk = d.date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, w.warehouse_name, c.c_city, d.d_year
),
ProfitRanking AS (
    SELECT 
        web_site_id, 
        total_profit, 
        total_orders, 
        avg_order_value, 
        warehouse_name, 
        c_city,
        d_year,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id, 
    total_profit, 
    total_orders, 
    avg_order_value, 
    warehouse_name, 
    c_city, 
    d_year 
FROM 
    ProfitRanking 
WHERE 
    profit_rank <= 5 
ORDER BY 
    d_year, profit_rank;
