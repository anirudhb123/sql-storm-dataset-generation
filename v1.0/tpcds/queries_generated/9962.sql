
WITH SalesSummary AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    WHERE 
        d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d_year, d_month_seq
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS customer_total_sales
    FROM 
        web_sales 
    JOIN 
        customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    ORDER BY 
        customer_total_sales DESC 
    LIMIT 10
)
SELECT 
    ss.d_year,
    ss.d_month_seq,
    ss.total_sales,
    ss.order_count,
    ss.total_quantity,
    ss.avg_profit,
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.customer_total_sales
FROM 
    SalesSummary ss
JOIN 
    TopCustomers tc ON ss.total_sales > 10000
ORDER BY 
    ss.d_year, ss.d_month_seq, tc.customer_total_sales DESC;
