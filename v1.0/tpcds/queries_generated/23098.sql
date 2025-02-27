
WITH RankedReturns AS (
    SELECT
        sr_returning_customer_sk,
        COUNT(sr_return_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
MostFrequentReturns AS (
    SELECT 
        rr.returning_customer_sk,
        rr.return_count,
        rr.total_return_amount,
        ROW_NUMBER() OVER (ORDER BY rr.total_return_amount DESC) AS rn
    FROM 
        RankedReturns rr
    WHERE 
        rr.return_count > (SELECT AVG(return_count) FROM RankedReturns)
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status
        END AS marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 0
            ELSE cd.cd_purchase_estimate
        END AS purchase_estimate
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.marital_status,
        TO_CHAR(c.c_birth_day, 'FM00') || '-' || TO_CHAR(c.c_birth_month, 'FM00') || '-' || TO_CHAR(c.c_birth_year, 'FM00') AS birth_date,
        COALESCE(r.return_count, 0) AS return_count,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        CustomerDemographics cd ON c.c_customer_sk = cd.c_customer_sk
    LEFT JOIN 
        MostFrequentReturns r ON c.c_customer_sk = r.returning_customer_sk
)
SELECT 
    rd.c_customer_id,
    rd.cd_gender,
    rd.marital_status,
    rd.birth_date,
    rd.return_count,
    CASE 
        WHEN rd.total_return_amount > 0 THEN ROUND(rd.total_return_amount / rd.return_count, 2)
        ELSE 0
    END AS avg_return_amount,
    CASE 
        WHEN EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    ReturnDetails rd
LEFT JOIN 
    customer c ON rd.c_customer_id = c.c_customer_id
WHERE 
    rd.return_count IS NOT NULL
ORDER BY 
    rd.return_count DESC, 
    rd.total_return_amount DESC
LIMIT 100;
