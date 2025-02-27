
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
CustomerDemographicDetails AS (
    SELECT 
        tc.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
    WHERE 
        tc.sales_rank <= 100
)

SELECT 
    tcd.c_customer_id, 
    tcd.total_sales,
    tcd.cd_gender,
    tcd.cd_marital_status,
    tcd.cd_education_status,
    tcd.cd_credit_rating
FROM 
    CustomerDemographicDetails tcd
JOIN 
    (SELECT 
         c_customer_id, 
         MAX(total_sales) as max_sales
     FROM 
         CustomerDemographics
     GROUP BY 
         c_customer_id) max_sales_results 
ON 
    tcd.c_customer_id = max_sales_results.c_customer_id
WHERE 
    tcd.total_sales = max_sales_results.max_sales
ORDER BY 
    tcd.total_sales DESC;
