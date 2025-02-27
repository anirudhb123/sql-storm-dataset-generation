
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
), 
AggregateReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_value
    FROM 
        CustomerInfo c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeBands AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ci.return_count,
    ar.total_return_value,
    CASE 
        WHEN ar.total_return_value IS NULL THEN 'No Returns'
        WHEN ar.total_return_value > 5000 THEN 'High Return'
        WHEN ar.total_return_value BETWEEN 1000 AND 5000 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    AggregateReturns ar
JOIN 
    CustomerInfo ci ON ar.c_customer_sk = ci.c_customer_sk
LEFT JOIN 
    IncomeBands ib ON ci.return_count > 0
WHERE 
    ci.return_count > 0 
    AND ci.cd_gender = 'F'
    AND EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_item_sk IN (
            SELECT sr_item_sk FROM RankedReturns WHERE total_returns > 5
        )
        AND ss.ss_customer_sk = ci.c_customer_sk
    )
ORDER BY 
    return_category, ar.total_return_value DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
