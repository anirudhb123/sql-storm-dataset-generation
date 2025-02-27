
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY COUNT(sr_ticket_number) DESC) AS rn
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS last_purchase_rn 
    FROM 
        customer c 
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
IncomeWithReturns AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        COALESCE(rr.return_count, 0) AS return_count,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN rr.return_count > 0 THEN 'Has Returns'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        RankedReturns rr ON ci.c_customer_sk = rr.sr_customer_sk 
)
SELECT 
    iwr.c_customer_sk,
    iwr.c_first_name,
    iwr.c_last_name,
    iwr.cd_gender,
    iwr.cd_marital_status,
    iwr.return_count,
    iwr.total_return_amt,
    iwr.return_status
FROM 
    IncomeWithReturns iwr
WHERE 
    iwr.last_purchase_rn = 1 
    AND iwr.return_count > (SELECT AVG(return_count) FROM RankedReturns)
ORDER BY 
    iwr.total_return_amt DESC;

