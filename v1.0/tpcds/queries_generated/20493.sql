
WITH RankedReturns AS (
    SELECT 
        COALESCE(sr_customer_sk, wr_returning_customer_sk) AS customer_sk,
        COALESCE(sr_item_sk, wr_item_sk) AS item_sk,
        COALESCE(sr_return_quantity, wr_return_quantity) AS return_quantity,
        CASE 
            WHEN sr_return_quantity IS NOT NULL THEN 'Store'
            WHEN wr_return_quantity IS NOT NULL THEN 'Web'
            ELSE 'Unknown'
        END AS return_source,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(sr_customer_sk, wr_returning_customer_sk) ORDER BY COALESCE(sr_return_time_sk, wr_returned_time_sk)) AS rn
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr ON sr_order_number = wr_order_number
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        COUNT(*) OVER (PARTITION BY cd_income_band_sk) AS income_band_count
    FROM customer_demographics
    WHERE cd_credit_rating IS NOT NULL
)
SELECT 
    c.c_customer_id,
    d.cd_gender,
    d.cd_marital_status,
    d.income_band_count,
    r.return_source,
    SUM(r.return_quantity) AS total_return_qty
FROM customer c
LEFT JOIN RankedReturns r ON c.c_customer_sk = r.customer_sk
LEFT JOIN CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE 
    (d.cd_marital_status IS NOT NULL OR r.return_quantity > 0) 
    AND (d.cd_gender = 'M' OR d.cd_gender IS NULL)
GROUP BY c.c_customer_id, d.cd_gender, d.cd_marital_status, d.income_band_count, r.return_source
HAVING 
    COUNT(r.return_quantity) > 2
    OR MAX(r.total_return_qty) > (SELECT AVG(return_quantity) FROM RankedReturns)
ORDER BY total_return_qty DESC NULLS LAST
LIMIT 100;
