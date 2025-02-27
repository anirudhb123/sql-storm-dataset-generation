
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown' 
            ELSE CASE 
                WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
                WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
                ELSE 'High'
            END 
        END AS purchase_estimate_band
    FROM 
        customer_demographics cd
),
RecentReturns AS (
    SELECT 
        cr.*, 
        ROW_NUMBER() OVER (PARTITION BY cr.cr_returning_customer_sk ORDER BY cr.cr_returned_date_sk DESC) AS rn
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity > 0
),
UnionedReturns AS (
    SELECT 
        customer_sk,
        total_returns AS returns,
        total_return_amount AS return_amount,
        'Store' AS source
    FROM 
        CustomerReturns
    UNION ALL
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_quantity) AS returns,
        SUM(wr_return_amt) AS return_amount,
        'Web' AS source
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
AggregatedReturns AS (
    SELECT 
        customer_sk,
        SUM(returns) AS total_returns,
        SUM(return_amount) AS total_return_amount
    FROM 
        UnionedReturns
    GROUP BY 
        customer_sk
)

SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cd.cd_gender,
    cd.purchase_estimate_band,
    ar.total_returns AS total_returns_last_period,
    ar.total_return_amount,
    CASE 
        WHEN ar.total_return_amount = 0 THEN 'No Returns'
        WHEN ar.total_return_amount > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_status
FROM 
    AggregatedReturns ar
JOIN 
    customer c ON c.c_customer_sk = ar.customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender IS NOT NULL AND 
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY 
    ar.total_return_amount DESC 
LIMIT 100;
