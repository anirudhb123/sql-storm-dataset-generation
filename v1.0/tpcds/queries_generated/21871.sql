
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        COUNT(sr_return_quantity) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(sr_return_quantity) DESC) AS rn
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        MAX(CASE WHEN cd_gender = 'M' THEN cd_purchase_estimate ELSE NULL END) AS male_purchase_estimate,
        MAX(CASE WHEN cd_gender = 'F' THEN cd_purchase_estimate ELSE NULL END) AS female_purchase_estimate,
        SUM(CASE WHEN cd_credit_rating IS NULL THEN 0 ELSE 1 END) AS valid_credits,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_dep_count IS NULL THEN 0 ELSE cd_dep_count END) AS total_dependents
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
ReturnsAggregated AS (
    SELECT 
        ci.c_customer_sk,
        ci.total_returns,
        ci.male_purchase_estimate,
        ci.female_purchase_estimate,
        ci.valid_credits,
        ci.married_count,
        ci.total_dependents,
        COALESCE(rr.return_count, 0) AS return_count,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt
    FROM CustomerInfo ci
    LEFT JOIN RankedReturns rr ON ci.c_customer_sk = rr.sr_item_sk
)
SELECT 
    r.c_customer_sk,
    r.total_returns,
    r.male_purchase_estimate,
    r.female_purchase_estimate,
    r.valid_credits,
    r.married_count,
    r.total_dependents,
    r.return_count,
    r.total_return_amt,
    CASE WHEN r.return_count > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_status,
    CASE 
        WHEN r.total_return_amt > 1000 THEN 'High Returns'
        WHEN r.total_return_amt BETWEEN 500 AND 1000 THEN 'Moderate Returns'
        ELSE 'Low Returns'
    END AS return_amount_status
FROM ReturnsAggregated r
WHERE 
    (r.total_returns IS NOT NULL AND r.total_returns > 0) 
    OR (r.valid_credits IS NOT NULL AND r.valid_credits > 5)
ORDER BY r.return_count DESC, r.total_return_amt DESC;
