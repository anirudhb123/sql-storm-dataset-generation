
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
TopCustomers AS (
    SELECT 
        customer_name,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    tc.customer_name,
    tc.total_sales,
    CASE 
        WHEN cd.cd_gender = 'F' THEN 'Female'
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Other' 
    END AS gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
