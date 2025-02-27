
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.reason_sk,
        RANK() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) AS return_rank
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
),
RecentCustomerReturns AS (
    SELECT 
        cr.customer_sk,
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amt) AS total_returned_amount
    FROM 
        CustomerReturns cr
    WHERE 
        cr.return_rank = 1
    GROUP BY 
        cr.customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(NULLIF(hd.hd_income_band_sk, -1)) AS income_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), ' - ', CAST(ib.ib_upper_bound AS VARCHAR))
        END AS income_range
    FROM 
        income_band ib
    WHERE 
        ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL
)
SELECT 
    c.customer_id,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    SUM(COALESCE(cr.total_returned_quantity, 0)) AS total_returns,
    SUM(COALESCE(cr.total_returned_amount, 0)) AS total_amount_refunded,
    ir.income_range
FROM 
    customer c
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    RecentCustomerReturns cr ON c.c_customer_sk = cr.customer_sk
LEFT JOIN 
    IncomeRanges ir ON cd.income_count BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound
WHERE 
    (cr.total_returned_quantity IS NOT NULL OR c.c_birth_year IS NOT NULL)
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_birth_month IS NOT NULL)
GROUP BY 
    c.customer_id, gender, ir.income_range
HAVING 
    SUM(COALESCE(cr.total_returned_quantity, 0)) > 0
ORDER BY 
    total_amount_refunded DESC
FETCH FIRST 10 ROWS ONLY;
