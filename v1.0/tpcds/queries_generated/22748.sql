
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_id,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        SUM(CASE WHEN sr_reason_sk IS NULL THEN 1 ELSE 0 END) AS null_reason_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        CD.cd_dep_count,
        CD.cd_dep_employed_count,
        CD.cd_dep_college_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
ReturnStatistics AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returns,
        cr.total_return_amount,
        cr.avg_return_quantity,
        cr.null_reason_count,
        NTILE(4) OVER (ORDER BY cr.total_return_amount DESC) AS return_amount_quartile
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.customer_id
),
TopReturningCustomers AS (
    SELECT 
        r.*,
        DENSE_RANK() OVER (PARTITION BY r.return_amount_quartile ORDER BY r.total_return_amount DESC) AS rank_within_quartile
    FROM 
        ReturnStatistics r
    WHERE 
        cr.null_reason_count = 0
)
SELECT 
    tc.customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_returns,
    tc.total_return_amount,
    tc.avg_return_quantity,
    CASE 
        WHEN tc.rank_within_quartile <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS return_category,
    CONCAT('Total Returns: ', CAST(tc.total_returns AS VARCHAR), ' | Avg Return Quantity: ', CAST(tc.avg_return_quantity AS VARCHAR)) AS return_summary
FROM 
    TopReturningCustomers tc
WHERE 
    tc.total_return_amount > (
        SELECT 
            AVG(total_return_amount) 
        FROM 
            ReturnStatistics
        WHERE 
            return_amount_quartile = tc.return_amount_quartile
    )
ORDER BY 
    tc.return_amount_quartile, 
    tc.total_return_amount DESC;
