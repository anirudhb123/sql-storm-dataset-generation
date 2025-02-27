
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.ticket_number) AS store_returns,
        COUNT(DISTINCT wr.order_number) AS web_returns,
        SUM(COALESCE(sr.return_quantity, 0) + COALESCE(wr.return_quantity, 0)) AS total_returned_qty
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ib.ib_income_band_sk,
        CASE
            WHEN cd.cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 20000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(COALESCE(crs.store_returns, 0) + COALESCE(crs.web_returns, 0)) AS total_returns,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count
FROM 
    CustomerDemographics cd
LEFT JOIN CustomerReturnStats crs ON cd.cd_demo_sk = crs.c_customer_sk
WHERE 
    cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    AND avg_purchase_estimate > 10000
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(COALESCE(crs.total_returned_qty, 0)) > 5
ORDER BY 
    total_returns DESC;

