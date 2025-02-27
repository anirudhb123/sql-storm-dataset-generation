
WITH RankedReturns AS (
    SELECT 
        sr.returning_customer_sk,
        COUNT(sr.returning_customer_sk) AS return_count,
        SUM(sr.return_amt_inc_tax) AS total_return_amount,
        DENSE_RANK() OVER (PARTITION BY sr.returning_customer_sk ORDER BY SUM(sr.return_amt_inc_tax) DESC) AS rank_return
    FROM store_returns sr
    WHERE sr.return_amt_inc_tax IS NOT NULL
    GROUP BY sr.returning_customer_sk
), CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(cd.cd_dep_count) AS total_dependencies,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_dep_employed_count) AS min_employed_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
), HighReturnCustomers AS (
    SELECT 
        rr.returning_customer_sk,
        rr.return_count,
        rr.total_return_amount,
        cs.total_dependencies,
        cs.max_purchase_estimate,
        cs.min_employed_count
    FROM RankedReturns rr
    JOIN CustomerStats cs ON rr.returning_customer_sk = cs.c_customer_sk
    WHERE rr.rank_return = 1
    AND rr.total_return_amount > (SELECT AVG(total_return_amount) FROM RankedReturns)
)
SELECT 
    c.c_customer_id,
    COALESCE(hrc.return_count, 0) AS high_return_count,
    COALESCE(hrc.total_return_amount, 0) AS total_return_amount,
    cs.total_dependencies,
    cs.max_purchase_estimate,
    cs.min_employed_count
FROM customer c
LEFT JOIN HighReturnCustomers hrc ON c.c_customer_sk = hrc.returning_customer_sk
JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
WHERE cs.total_dependencies IS NOT NULL OR hrc.return_count IS NULL
ORDER BY high_return_count DESC, total_return_amount DESC
LIMIT 50;
