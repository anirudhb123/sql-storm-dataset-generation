
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.web_order_count,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS total_web_sales,
    COALESCE(tc.web_order_count, 0) AS web_order_count,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers' 
    END AS customer_category,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT ca_address_sk FROM customer WHERE c_customer_sk = tc.c_customer_sk)
WHERE 
    tc.sales_rank IS NOT NULL OR ca.ca_address_sk IS NOT NULL
ORDER BY 
    tc.total_web_sales DESC, tc.c_last_name ASC;
