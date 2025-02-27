
WITH RankedReturns AS (
    SELECT 
        sr.store_sk,
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.return_quantity,
        sr.return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr.store_sk ORDER BY sr.returned_date_sk DESC, sr.return_time_sk DESC) AS return_rank
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
        AND EXISTS (
            SELECT 1 
            FROM item i 
            WHERE i.i_item_sk = sr.sr_item_sk AND i.i_current_price IS NOT NULL
        )
),
FirstReturn AS (
    SELECT 
        store_sk,
        MIN(returned_date_sk) AS first_return_date_sk
    FROM 
        RankedReturns 
    WHERE 
        return_rank = 1
    GROUP BY 
        store_sk
),
ReturnSummary AS (
    SELECT 
        sr.store_sk,
        COUNT(*) AS total_returns,
        SUM(sr.return_quantity) AS total_returned_quantity,
        SUM(sr.return_amt) AS total_returned_amt
    FROM 
        RankedReturns sr
    JOIN 
        FirstReturn fr ON sr.store_sk = fr.store_sk
    WHERE 
        sr.returned_date_sk = fr.first_return_date_sk
    GROUP BY 
        sr.store_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.dep_count,
        COUNT(DISTINCT ws.bill_customer_sk) AS web_sales_count
    FROM 
        customer_demographics cd
    JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.gender, cd.marital_status, cd.education_status, cd.dep_count
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COUNT(customer.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ib.ib_income_band_sk, hd.hd_buy_potential
)
SELECT 
    rs.store_sk,
    rs.total_returns,
    rs.total_returned_quantity,
    rs.total_returned_amt,
    cd.gender,
    cd.marital_status,
    ib.buy_potential,
    ib.customer_count,
    ib.female_count,
    ib.male_count
FROM 
    ReturnSummary rs
JOIN 
    CustomerDemographics cd ON cd.web_sales_count > (SELECT AVG(web_sales_count) FROM CustomerDemographics)
JOIN 
    IncomeBand ib ON ib.customer_count > 10
ORDER BY 
    rs.store_sk, ib.buy_potential DESC
LIMIT 100 OFFSET 0
UNION DISTINCT
SELECT 
    sr.store_sk,
    SUM(sr.return_quantity) AS total_returns,
    SUM(sr.return_amt) AS total_returned_quantity,
    NULL AS total_returned_amt,
    NULL AS gender,
    NULL AS marital_status,
    'Overall' AS buy_potential,
    COUNT(DISTINCT sr.returning_customer_sk) AS customer_count,
    NULL AS female_count,
    NULL AS male_count
FROM 
    store_returns sr
WHERE 
    sr.return_quantity > 0
GROUP BY 
    sr.store_sk
HAVING 
    COUNT(DISTINCT sr.returning_customer_sk) > 5;
