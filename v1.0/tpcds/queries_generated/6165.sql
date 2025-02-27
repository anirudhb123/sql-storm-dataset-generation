
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        (c.c_birth_year BETWEEN 1980 AND 1990) 
    GROUP BY 
        c.c_customer_id
),
BestCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    bc.c_customer_id,
    bc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.cd_education_status
FROM 
    BestCustomers bc
JOIN 
    customer_demographics cd ON bc.c_customer_id = cd.cd_demo_sk
WHERE 
    bc.sales_rank <= 10
ORDER BY 
    bc.total_sales DESC;
