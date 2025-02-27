
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
)
SELECT 
    sd.c_customer_id,
    sd.total_sales,
    sd.total_transactions,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    SalesData sd
LEFT JOIN 
    CustomerDemographics cd ON sd.c_customer_id = cd.cd_demo_sk
WHERE 
    sd.total_sales > 5000
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
