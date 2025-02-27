
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        RankedCustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 100
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopCustomers AS tc
JOIN 
    customer_demographics AS cd ON tc.c_customer_id = cd.cd_demo_sk
ORDER BY 
    tc.total_sales DESC;
