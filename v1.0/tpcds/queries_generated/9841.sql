
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_store_sales,
        SUM(ws.ws_sales_price) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_store_sales + cs.total_web_sales AS total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    DENSE_RANK() OVER (ORDER BY tc.total_sales DESC) AS sales_rank,
    tc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    cd.cd_marital_status = 'M'
    AND cd.cd_gender = 'F'
    AND ca.ca_state IN ('CA', 'NY')
ORDER BY 
    sales_rank;
