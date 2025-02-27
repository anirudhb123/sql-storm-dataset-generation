
WITH RECURSIVE CustomerReturns AS (
    SELECT sr_returned_date_sk, SUM(sr_return_quantity) AS total_returned, sr_cdemo_sk
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_cdemo_sk
    UNION ALL
    SELECT sr_returned_date_sk, SUM(sr_return_quantity) AS total_returned, sr_cdemo_sk
    FROM store_returns sr
    INNER JOIN CustomerReturns cr ON sr_cdemo_sk = cr.sr_cdemo_sk
    WHERE sr_returned_date_sk > cr.returned_date_sk
    GROUP BY sr_returned_date_sk, sr_cdemo_sk
),
TotalReturns AS (
    SELECT cr.sr_cdemo_sk, SUM(cr.total_returned) AS lifetime_returns
    FROM CustomerReturns cr
    GROUP BY cr.sr_cdemo_sk
),
CustomerDemographics AS (
    SELECT cd_gender, cd_marital_status, cd_purchase_estimate, ib_upper_bound
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT cdGender, cdMaritalStatus, SUM(tr.lifetime_returns) AS TotalReturns, COUNT(DISTINCT c.c_customer_sk) AS CustomerCount,
       CASE
           WHEN COUNT(c.c_customer_sk) > 0 THEN SUM(tr.lifetime_returns) / COUNT(DISTINCT c.c_customer_sk)
           ELSE 0
       END AS AverageReturnsPerCustomer
FROM TotalReturns tr
JOIN customer c ON tr.sr_cdemo_sk = c.c_current_cdemo_sk
JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN date_dim dd ON dd.d_date_sk = tr.sr_returned_date_sk
WHERE (cd_purchase_estimate BETWEEN 100 AND 1000 OR cd_purchase_estimate IS NULL)
  AND cd_gender IN ('M', 'F') 
  AND NOT EXISTS (SELECT 1 FROM customer x WHERE x.c_customer_sk = c.c_customer_sk AND x.c_birth_year < 1970)
GROUP BY cdGender, cdMaritalStatus
ORDER BY cdGender, cdMaritalStatus DESC
FETCH FIRST 10 ROWS ONLY;
