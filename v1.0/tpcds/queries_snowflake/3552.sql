
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_web_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_web_orders
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS total_sales,
    COALESCE(tc.total_web_orders, 0) AS total_orders,
    CASE 
        WHEN tc.total_web_sales IS NULL THEN 'No Sales'
        WHEN tc.total_web_sales > 5000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_order_count,
    SUM(sr.sr_return_amt) AS total_returns
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = tc.c_customer_sk
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = tc.c_customer_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE 
    ca.ca_state = 'CA' OR ca.ca_state IS NULL
GROUP BY 
    tc.c_first_name, tc.c_last_name, tc.total_web_sales, tc.total_web_orders
ORDER BY 
    total_sales DESC;
