
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_profit) AS average_profit,
        COUNT(DISTINCT ws.ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023 
        AND ws.net_paid_inc_tax > 0
    GROUP BY 
        ws.web_site_id
),
RankedSales AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        average_profit,
        unique_customers,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id,
    r.total_sales,
    r.total_orders,
    r.average_profit,
    r.unique_customers,
    r.sales_rank,
    CASE 
        WHEN r.average_profit < 100 THEN 'Low Profit'
        WHEN r.average_profit BETWEEN 100 AND 500 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
