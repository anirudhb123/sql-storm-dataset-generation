
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.*,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        (SELECT COUNT(*) 
         FROM store s 
         WHERE s.s_store_sk = sr.s_store_sk) AS store_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_returns DESC) AS rn
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
)
SELECT 
    hrc.sr_customer_sk,
    hrc.total_returns,
    hrc.avg_return_amt,
    hrc.return_count,
    hrc.cd_gender,
    hrc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    'High Return Customer' AS customer_category
FROM 
    HighReturnCustomers hrc
LEFT JOIN 
    household_demographics hd ON hrc.cd_income_band_sk = hd.hd_income_band_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    hrc.rn <= 5
ORDER BY 
    hrc.cd_gender, hrc.total_returns DESC
UNION ALL
SELECT 
    hrc.sr_customer_sk,
    0 AS total_returns,
    NULL AS avg_return_amt,
    0 AS return_count,
    hrc.cd_gender,
    hrc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    'No Returns' AS customer_category
FROM 
    HighReturnCustomers hrc
RIGHT JOIN 
    household_demographics hd ON hrc.cd_income_band_sk = hd.hd_income_band_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    hrc.sr_customer_sk IS NULL
ORDER BY 
    cd_gender, total_returns DESC;
