
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1960 AND 2000
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_country = 'USA' AND cd.cd_gender = 'M'
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10'
        WHEN tc.sales_rank <= 50 THEN 'Top 50'
        ELSE 'Other'
    END AS customer_category
FROM 
    TopCustomers tc
UNION ALL
SELECT 
    c.c_customer_id,
    0 AS total_sales,
    'No Sales' AS customer_category
FROM 
    customer c
WHERE 
    c.c_customer_id NOT IN (SELECT c_customer_id FROM TopCustomers)
ORDER BY 
    total_sales DESC;
