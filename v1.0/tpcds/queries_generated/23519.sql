
WITH RankedReturns AS (
    SELECT 
        sr.customer_sk,
        sr.returned_quantity,
        sr.return_amt,
        RANK() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) AS return_rank
    FROM 
        store_returns sr
    WHERE 
        sr.returned_quantity > 0
        AND sr.return_amt IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        rr.customer_sk,
        SUM(rr.returned_quantity) AS total_returned_quantity,
        SUM(rr.return_amt) AS total_returned_amt
    FROM 
        RankedReturns rr
    WHERE 
        rr.return_rank <= 3
    GROUP BY 
        rr.customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
    FROM 
        income_band ib
),
DemographicSummary AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_income_band_sk IS NOT NULL THEN 'In income band'
            ELSE 'Out of income band'
        END AS income_band_status
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        IncomeBand ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ds.customer_sk,
    ds.total_returned_quantity,
    ds.total_returned_amt,
    ds_g.gender,
    ds_g.marital_status,
    ds_g.income_band_sk,
    ds_g.income_band_status,
    COUNT(*) OVER (PARTITION BY ds.customer_sk) AS demographic_count,
    ROW_NUMBER() OVER (ORDER BY ds.total_returned_amt DESC) AS ranking
FROM 
    AggregateReturns ds
JOIN 
    DemographicSummary ds_g ON ds.customer_sk = ds_g.c_customer_sk
WHERE 
    ds.total_returned_amt > 0
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE 
            wr.returning_customer_sk = ds.customer_sk
            AND wr.return_quantity > 0
            AND wr.return_amt IS NOT NULL
    )
    AND ds_g.income_band_status = 'In income band'
ORDER BY 
    ds.total_returned_amt DESC, ds.total_returned_quantity ASC;
