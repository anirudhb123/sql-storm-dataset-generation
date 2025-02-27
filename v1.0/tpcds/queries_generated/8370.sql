
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        * 
    FROM 
        CustomerSales 
    ORDER BY 
        total_sales DESC 
    LIMIT 10
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(tc.c_customer_sk) AS customer_count,
        SUM(tc.total_sales) AS total_sales
    FROM 
        TopCustomers tc
    JOIN 
        CustomerDemographics cd ON tc.c_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(tc.c_customer_sk) AS customer_count,
    SUM(tc.total_sales) AS total_sales,
    RANK() OVER (ORDER BY SUM(tc.total_sales) DESC) AS sales_rank
FROM 
    SalesByDemographics cd
JOIN 
    TopCustomers tc ON cd.c_customer_sk = tc.c_customer_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales DESC;
