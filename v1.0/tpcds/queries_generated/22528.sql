
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.item_sk, 
        sr.customer_sk, 
        sr.cdemo_sk, 
        sr.hdemo_sk, 
        sr.addr_sk, 
        sr.store_sk, 
        sr.reason_sk, 
        sr.ticket_number, 
        sr.return_quantity, 
        sr.return_amt, 
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY sr.ticket_number) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
), 
TopReturningCustomers AS (
    SELECT 
        cr.customer_sk, 
        SUM(cr.return_amount) AS total_returned_amount
    FROM 
        CustomerReturns cr
    WHERE 
        cr.returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr.customer_sk
    HAVING 
        SUM(cr.return_amount) > 1000
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender = 'F' AND 
        (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S')
), 
WealthyCustomers AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown' 
            ELSE 
            CASE 
                WHEN cd.cd_purchase_estimate > 50000 THEN 'Wealthy'
                WHEN cd.cd_purchase_estimate BETWEEN 20000 AND 50000 THEN 'Affluent'
                ELSE 'Modest'
            END 
        END AS income_category
    FROM 
        customer c
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_name IS NOT NULL AND 
        c.c_last_name IS NOT NULL
), 
FinalReport AS (
    SELECT 
        wc.c_customer_id,
        COUNT(DISTINCT cr.ticket_number) AS total_returns,
        SUM(cr.return_amt) AS total_returned,
        COUNT(DISTINCT cr.ticket_number) / NULLIF(SUM(cr.return_amt), 0) AS return_ratio
    FROM 
        TopReturningCustomers tr
    JOIN 
        WealthyCustomers wc ON tr.customer_sk = wc.c_customer_id
    LEFT JOIN 
        store_returns cr ON cr.customer_sk = wc.c_customer_id
    GROUP BY 
        wc.c_customer_id
)
SELECT 
    c.c_customer_id,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.total_returned, 0) AS total_returned,
    CASE 
        WHEN COALESCE(f.return_ratio, 0) > 1 THEN 'High Risk' 
        ELSE 'Low Risk' 
    END AS risk_status
FROM 
    customer c
LEFT JOIN 
    FinalReport f ON c.c_customer_id = f.c_customer_id
WHERE 
    c.c_birth_year IS NOT NULL
ORDER BY 
    risk_status DESC, 
    total_returned DESC;
