
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        sr_return_time_sk,
        COALESCE(SUM(sr_return_amt_inc_tax) OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_return_time_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS cumulative_return_amt,
        RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_return_time_sk DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Uncertain'
            ELSE CASE 
                WHEN cd.cd_purchase_estimate BETWEEN 0 AND 100 THEN 'Low'
                WHEN cd.cd_purchase_estimate BETWEEN 101 AND 500 THEN 'Medium'
                WHEN cd.cd_purchase_estimate > 500 THEN 'High'
            END
        END AS purchase_estimate_category
    FROM 
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_month IS NOT NULL
),
ReturnStatistics AS (
    SELECT 
        cr.returning_customer_sk,
        cr.return_rank,
        COUNT(*) AS total_returns,
        AVG(cr.cumulative_return_amt) AS avg_return_amount,
        MAX(cr.cumulative_return_amt) AS max_return_amount
    FROM RankedReturns cr
    WHERE 
        cr.return_rank <= 5
    GROUP BY cr.returning_customer_sk, cr.return_rank
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    rs.total_returns,
    rs.avg_return_amount,
    rs.max_return_amount,
    CASE
        WHEN rs.total_returns IS NULL THEN 'No Returns'
        WHEN rs.total_returns > 0 AND cd.purchase_estimate_category = 'High' THEN 'Valuable Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM 
    CustomerData cd
LEFT JOIN 
    ReturnStatistics rs ON cd.c_customer_sk = rs.returning_customer_sk
WHERE 
    (cd.cd_gender IS NOT NULL AND cd.cd_gender IN ('M', 'F'))
    OR (cd.purchase_estimate_category = 'High' AND rs.total_returns IS NOT NULL)
ORDER BY 
    cd.c_last_name ASC, cd.c_first_name DESC;
