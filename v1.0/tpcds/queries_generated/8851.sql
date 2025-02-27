
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rnk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459740 AND 2459745  -- Example date range
    GROUP BY ws.bill_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        r.bill_customer_sk, 
        r.c_first_name, 
        r.c_last_name, 
        r.total_sales, 
        r.order_count
    FROM RankedSales r
    WHERE r.rnk <= 10  -- Get top 10 customers based on sales
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_sales,
    tc.order_count,
    d.d_year,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(ws.ws_order_number) AS total_orders
FROM TopCustomers tc
JOIN web_sales ws ON tc.bill_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_sales, 
    tc.order_count, 
    d.d_year
ORDER BY total_sales DESC;
