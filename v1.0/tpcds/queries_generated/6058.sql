
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        c.c_country,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, c.c_country
), RankedSales AS (
    SELECT 
        web_site_id,
        c_country,
        total_sales,
        total_orders,
        avg_profit,
        RANK() OVER (PARTITION BY c_country ORDER BY total_sales DESC) as sales_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id,
    c_country,
    total_sales,
    total_orders,
    avg_profit,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 5
ORDER BY 
    c_country, total_sales DESC;
