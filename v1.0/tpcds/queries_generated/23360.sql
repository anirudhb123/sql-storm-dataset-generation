
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amt) AS total_returned_amount,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rn
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
FilteredDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(c.c_birth_year, 0) AS birth_year
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
MaxReturns AS (
    SELECT 
        cr.returning_customer_sk,
        MAX(cr.total_returned_amount) AS max_returned_amount
    FROM CustomerReturns cr
    WHERE cr.total_returned_quantity > 10
    GROUP BY cr.returning_customer_sk
)
SELECT 
    f.cd_demo_sk,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_purchase_estimate,
    f.birth_year,
    CASE 
        WHEN m.max_returned_amount IS NOT NULL THEN 'High Returner'
        ELSE 'Low Returner'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY f.cd_demo_sk ORDER BY f.cd_purchase_estimate DESC) AS rank
FROM FilteredDemographics f
LEFT JOIN MaxReturns m ON f.cd_demo_sk = m.returning_customer_sk
WHERE f.cd_gender = 'F' OR (f.cd_marital_status IS NULL AND f.cd_purchase_estimate < 2000)
ORDER BY f.cd_purchase_estimate DESC, rank
LIMIT 100
UNION
SELECT 
    f.cd_demo_sk,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_purchase_estimate,
    f.birth_year,
    'Retired' AS return_category,
    ROW_NUMBER() OVER (PARTITION BY f.cd_demo_sk ORDER BY f.cd_purchase_estimate) AS rank
FROM FilteredDemographics f
WHERE f.birth_year < (EXTRACT(YEAR FROM CURRENT_DATE) - 65)
AND NOT EXISTS (
    SELECT 1 
    FROM MaxReturns m 
    WHERE m.returning_customer_sk = f.cd_demo_sk
)
ORDER BY f.cd_purchase_estimate ASC;
