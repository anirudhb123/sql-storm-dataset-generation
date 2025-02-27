
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        customer c 
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk 
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    DATEDIFF(NOW(), DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 1 MONTH), '%Y-%m-01')) AS days_since_last_order,
    CASE 
        WHEN tc.order_count > 10 THEN 'Frequent'
        WHEN tc.order_count BETWEEN 5 AND 10 THEN 'Occasional'
        ELSE 'Rare'
    END AS customer_type
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_sales DESC;
