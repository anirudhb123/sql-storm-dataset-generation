
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_returned_date_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        1 AS return_level
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 20230101 AND 20230131
    UNION ALL
    SELECT 
        cr_returning_customer_sk,
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amount AS wr_return_amt,
        cr_return_tax AS wr_return_tax,
        return_level + 1
    FROM catalog_returns cr
    JOIN CustomerReturns crs ON cr.refunded_customer_sk = crs.wr_returning_customer_sk
    WHERE cr.returned_date_sk BETWEEN 20230101 AND 20230131
)
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT cr.wr_returning_customer_sk) AS total_customers_returned,
    SUM(cr.wr_return_quantity) AS total_returned_quantity,
    ROUND(SUM(cr.wr_return_amt), 2) AS total_returned_amount,
    STRING_AGG(DISTINCT d.d_day_name) FILTER (WHERE cr.return_level = 1) AS first_level_return_days,
    COALESCE(SUM(DISTINCT CASE 
        WHEN cr.wr_return_quantity IS NULL THEN 0 
        ELSE cr.wr_return_quantity END), 0) AS valid_return_quantity
FROM CustomerReturns cr
JOIN customer c ON c.c_customer_sk = cr.wr_returning_customer_sk
JOIN date_dim d ON d.d_date_sk = cr.wr_returned_date_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE c.c_birth_year IS NOT NULL AND
      (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
GROUP BY c.c_customer_id
HAVING COUNT(DISTINCT cr.wr_returning_customer_sk) > (
    SELECT COUNT(*) FROM customer WHERE c_birth_month = 1 AND c_birth_year <= 1980
)
ORDER BY total_returned_quantity DESC
LIMIT 10 OFFSET 5;
