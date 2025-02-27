
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    WHERE 
        d.d_year >= 2022
    GROUP BY 
        ws.web_site_id, d.d_year, d.d_month_seq
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_orders,
        cs.total_profit
    FROM 
        CustomerStats cs 
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    ORDER BY 
        cs.total_profit DESC
    LIMIT 10
),
AggregatedSales AS (
    SELECT 
        sd.web_site_id,
        AVG(sd.total_quantity_sold) AS avg_quantity,
        AVG(sd.total_sales) AS avg_sales
    FROM 
        SalesData sd 
    GROUP BY 
        sd.web_site_id
)
SELECT 
    tc.c_customer_id,
    tc.total_orders,
    tc.total_profit,
    as.avg_quantity,
    as.avg_sales
FROM 
    TopCustomers tc 
JOIN 
    AggregatedSales as ON tc.total_orders > as.avg_quantity
ORDER BY 
    tc.total_profit DESC;
