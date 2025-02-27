
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1970
        AND c.c_birth_year <= 1990
        AND ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COUNT(rr.cr_returned_date_sk) AS return_count,
    (SELECT COUNT(DISTINCT ws1.ws_order_number) FROM web_sales ws1 WHERE ws1.ws_bill_customer_sk = tc.c_customer_sk) AS unique_orders,
    MAX(rr.cr_return_amount) AS max_return_amount
FROM 
    TopCustomers tc
LEFT JOIN 
    catalog_returns rr ON tc.c_customer_sk = rr.cr_returning_customer_sk
GROUP BY 
    tc.c_first_name, tc.c_last_name, tc.total_sales
ORDER BY 
    tc.total_sales DESC
LIMIT 10;
