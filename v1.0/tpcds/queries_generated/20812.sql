
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY wr_return_quantity DESC) AS rn
    FROM 
        web_returns
    WHERE 
        wr_return_quantity IS NOT NULL
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        CASE WHEN cd.gender IS NULL THEN 'Unknown' ELSE cd.gender END AS gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        cd.cd_dep_count,
        SUM(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, cd.gender, hd.hd_income_band_sk, cd.cd_dep_count
),
IncomeDistribution AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(CASE WHEN cd.total_returns > 0 THEN 1 ELSE 0 END) AS customers_with_returns,
        COUNT(cd.c_customer_id) AS total_customers,
        (SUM(CASE WHEN cd.total_returns > 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(cd.c_customer_id)) * 100 AS return_rate_percentage
    FROM 
        income_band ib
    LEFT JOIN 
        CustomerData cd ON ib.ib_income_band_sk = cd.income_band
    GROUP BY 
        ib.ib_income_band_sk
)

SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    id.customers_with_returns,
    id.total_customers,
    id.return_rate_percentage,
    CASE 
        WHEN id.return_rate_percentage IS NULL THEN 'No Data'
        WHEN id.return_rate_percentage > 50 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_category
FROM 
    income_band ib
LEFT JOIN 
    IncomeDistribution id ON ib.ib_income_band_sk = id.ib_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
