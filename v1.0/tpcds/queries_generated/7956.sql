
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_transaction_value
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_transactions,
        cs.avg_transaction_value,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 10000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        dc.income_bracket
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band dc ON hd.hd_income_band_sk = dc.ib_income_band_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_transactions,
    tc.avg_transaction_value,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.income_bracket
FROM 
    TopCustomers tc
JOIN 
    CustomerDemographics cd ON tc.c_customer_id = cd.cd_demo_sk
ORDER BY 
    tc.total_sales DESC, 
    cd.cd_gender ASC;
