
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 
              AND d.d_month_seq < (SELECT MAX(d2.d_month_seq) FROM date_dim d2 WHERE d2.d_year = 2023)
        )
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    COALESCE((SELECT COUNT(*) 
              FROM store_returns sr 
              WHERE sr.sr_customer_sk = c.c_customer_sk AND sr.sr_return_quantity > 0), 0) AS return_count,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.order_count = 0 THEN 'No Orders'
        ELSE 'Active Customer'
    END AS customer_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM web_returns wr WHERE wr.wr_returning_customer_sk = c.c_customer_sk)
        THEN 'Returned Item'
        ELSE 'No Returns'
    END AS return_status
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.customer_id = c.c_customer_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC
LIMIT 5;
