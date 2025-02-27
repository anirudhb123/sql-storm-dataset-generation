
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        SUM(total_sales) AS total_spent,
        COUNT(DISTINCT d_year) AS years_active
    FROM 
        CustomerOrders c
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    tc.customer_id,
    tc.total_spent,
    coalesce(cd.cd_gender, 'N/A') AS gender,
    coalesce(cd.cd_marital_status, 'N/A') AS marital_status,
    coalesce(cd.cd_education_status, 'N/A') AS education_status
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cd ON tc.customer_id = cd.cd_demo_sk
ORDER BY 
    tc.total_spent DESC, tc.customer_id;
