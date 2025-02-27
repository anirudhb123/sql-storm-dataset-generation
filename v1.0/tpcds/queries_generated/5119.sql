
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_tax) AS total_returned_tax,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
ReturnAnalysis AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        cr.total_returned_tax,
        cr.total_returns
    FROM CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
), 
ReturnSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
        SUM(NVL(cr.total_returned_quantity, 0)) AS total_barang_returned,
        SUM(NVL(cr.total_returned_amount, 0)) AS total_returned_amount,
        AVG(cr.total_returns) AS avg_returns_per_customer
    FROM ReturnAnalysis cr
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    r.cd_gender,
    r.cd_marital_status,
    r.customer_count,
    r.total_barang_returned,
    r.total_returned_amount,
    r.avg_returns_per_customer
FROM ReturnSummary r
ORDER BY customer_count DESC, total_returned_amount DESC
LIMIT 100;
