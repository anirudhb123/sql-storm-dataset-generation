
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
        JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2458584 AND 2459300 -- Example date range
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000 -- Filter for total sales greater than $1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hs.c_customer_id
    FROM 
        customer_demographics cd
        JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
        JOIN HighSpenders hs ON c.c_customer_id = hs.c_customer_id
)
SELECT 
    dem.cd_gender,
    dem.cd_marital_status,
    COUNT(dem.c_customer_id) AS number_of_customers,
    AVG(cs.total_sales) AS avg_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimation
FROM 
    CustomerDemographics dem
    JOIN CustomerSales cs ON dem.c_customer_id = cs.c_customer_id
    LEFT JOIN customer_demographics cd ON dem.c_customer_id = cd.cd_demo_sk
GROUP BY 
    dem.cd_gender,
    dem.cd_marital_status
ORDER BY 
    number_of_customers DESC, avg_sales DESC
LIMIT 10;
