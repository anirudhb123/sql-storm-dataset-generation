
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
), CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_income_band_sk AS household_income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS full_name,
    cd.cd_gender,
    COALESCE(ROUND(AVG(rr.sr_return_amt), 2), 0) AS average_return_amount,
    COUNT(rr.sr_return_quantity) AS total_returns,
    CASE 
        WHEN cd.cd_income_band_sk IS NOT NULL THEN 'Income Band Exists'
        ELSE 'No Income Band'
    END AS income_band_status,
    DENSE_RANK() OVER (ORDER BY AVG(rr.sr_return_amt) DESC) AS return_rank
FROM 
    CustomerData cd
LEFT JOIN 
    RankedReturns rr ON cd.c_customer_sk = rr.sr_customer_sk
GROUP BY 
    cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_income_band_sk
HAVING 
    COUNT(rr.sr_return_quantity) > 0
ORDER BY 
    average_return_amount DESC, full_name ASC
LIMIT 100;
