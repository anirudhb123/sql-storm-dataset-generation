
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2459604 AND 2459938 -- Date range for sales
    GROUP BY c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_credit_rating
    FROM customer_demographics cd
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM income_band ib
),
DemographicsWithIncome AS (
    SELECT 
        cd.*,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM CustomerDemographics cd
    JOIN IncomeBand ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
),
FinalSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_quantity,
        cs.total_net_paid,
        di.cd_gender,
        di.cd_marital_status,
        di.ib_lower_bound,
        di.ib_upper_bound
    FROM CustomerSales cs
    JOIN DemographicsWithIncome di ON cs.c_customer_id = di.cd_demo_sk
)
SELECT
    fs.cd_gender,
    fs.cd_marital_status,
    COUNT(fs.c_customer_id) AS customer_count,
    SUM(fs.total_quantity) AS total_quantity,
    SUM(fs.total_net_paid) AS total_net_paid,
    AVG(fs.total_net_paid) AS avg_net_paid,
    AVG(fs.total_quantity) AS avg_quantity,
    MIN(fs.ib_lower_bound) AS min_income_band,
    MAX(fs.ib_upper_bound) AS max_income_band
FROM FinalSales fs
GROUP BY fs.cd_gender, fs.cd_marital_status
ORDER BY cd_gender, cd_marital_status;
