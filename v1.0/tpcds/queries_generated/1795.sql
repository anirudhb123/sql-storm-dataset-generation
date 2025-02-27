
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
),
SalesWithDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_transactions,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    swd.c_customer_sk,
    swd.total_sales,
    swd.total_transactions,
    swd.cd_gender,
    swd.cd_marital_status,
    COALESCE(swd.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(swd.ib_upper_bound, 0) AS income_upper_bound,
    DENSE_RANK() OVER (PARTITION BY swd.cd_gender ORDER BY swd.total_sales DESC) AS gender_rank,
    ROW_NUMBER() OVER (ORDER BY swd.total_sales DESC) AS overall_rank
FROM 
    SalesWithDemographics swd
WHERE 
    swd.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
ORDER BY 
    swd.total_sales DESC
LIMIT 100;
