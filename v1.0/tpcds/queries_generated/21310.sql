
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
PurchaseEstimates AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM
        customer_demographics cd
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT
    cr.c_customer_id,
    cr.total_store_returns,
    cr.total_web_returns,
    pe.cd_purchase_estimate,
    CASE 
        WHEN cr.total_store_returns + cr.total_web_returns > 0 THEN 'Returned'
        WHEN pe.cd_purchase_estimate >= 10000 THEN 'High Value'
        ELSE 'Normal'
    END AS customer_value_status,
    CASE 
        WHEN cr.total_store_returns IS NULL 
            OR cr.total_web_returns IS NULL THEN 'Need Review'
        ELSE 'Checked' 
    END AS review_status,
    SUBSTRING(cr.c_customer_id, 1, 5) || '... on ' || TO_CHAR(NOW(), 'YYYY/MM/DD') AS notification
FROM
    CustomerReturns cr
LEFT JOIN PurchaseEstimates pe ON cr.c_customer_sk = pe.cd_demo_sk
WHERE
    cr.total_store_returns + cr.total_web_returns > 0
    OR pe.cd_purchase_estimate >= 10000
ORDER BY
    cr.total_store_returns DESC,
    cr.total_web_returns DESC,
    pe.cd_purchase_estimate DESC
FETCH FIRST 10 ROWS ONLY;
