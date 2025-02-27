
WITH RankedReturns AS (
    SELECT 
        wr.returning_customer_sk,
        wr.return_quantity,
        wr.return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY wr.returned_date_sk DESC) AS rn
    FROM 
        web_returns wr
    WHERE 
        wr.return_quantity IS NOT NULL AND wr.return_quantity > 0
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        SUM(COALESCE(rr.return_quantity, 0)) AS total_returns,
        COUNT(rr.return_quantity) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        RankedReturns rr ON c.c_customer_sk = rr.returning_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
IncomeDistribution AS (
    SELECT 
        h.hd_demo_sk,
        ib.ib_income_band_sk,
        SUM(hd.dep_count) AS total_dependents,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        customer c ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        h.hd_demo_sk, ib.ib_income_band_sk
),
FinalReport AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.gender,
        cs.total_returns,
        cs.return_count,
        CASE 
            WHEN cs.total_returns > 10 THEN 'High Return Customer'
            WHEN cs.total_returns BETWEEN 1 AND 10 THEN 'Moderate Return Customer'
            ELSE 'Low Return Customer'
        END AS return_category,
        COALESCE(id.total_dependents, 0) AS total_dependents,
        COALESCE(id.customer_count, 0) AS related_customers
    FROM 
        CustomerStats cs
    LEFT JOIN 
        IncomeDistribution id ON cs.c_customer_sk = id.hd_demo_sk
)

SELECT 
    fr.*,
    (SELECT AVG(total_returns) FROM CustomerStats) AS avg_returns,
    (SELECT MAX(total_dependents) FROM IncomeDistribution) AS max_dependents,
    (SELECT MIN(customer_count) FROM IncomeDistribution WHERE customer_count > 0) AS min_related_customers
FROM 
    FinalReport fr
WHERE 
    fr.total_returns IS NOT NULL
ORDER BY 
    fr.total_returns DESC, fr.return_category DESC
FETCH FIRST 100 ROWS ONLY;
