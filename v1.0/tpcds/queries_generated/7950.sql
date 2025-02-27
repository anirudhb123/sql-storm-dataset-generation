
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_quantity,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 0
),
CustomerDemographics AS (
    SELECT 
        tc.customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    cd.customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_dep_count,
    tc.total_quantity,
    tc.total_sales
FROM 
    CustomerDemographics cd
JOIN 
    TopCustomers tc ON cd.customer_id = tc.customer_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
