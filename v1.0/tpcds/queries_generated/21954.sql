
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rnk,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_item_sk) as total_returned,
        SUM(sr_return_amount) OVER (PARTITION BY sr_item_sk) AS total_amount_refunded
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL 
        AND sr_return_quantity > 0
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
HighValueReturns AS (
    SELECT 
        rr.sr_item_sk,
        rr.sr_customer_sk,
        rr.total_returned,
        rr.total_amount_refunded,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        RankedReturns rr
    JOIN 
        CustomerDemographics cd ON rr.sr_customer_sk = cd.cd_demo_sk
    WHERE 
        rr.rnk = 1 AND 
        rr.total_returned > (SELECT AVG(total_returned) FROM RankedReturns) 
        AND (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
)
SELECT 
    hvr.sr_item_sk,
    hvr.sr_customer_sk,
    hvr.total_returned,
    hvr.total_amount_refunded,
    CASE 
        WHEN hvr.total_amount_refunded IS NULL THEN 'No Refunds'
        ELSE 'Refunded'
    END AS refund_status
FROM 
    HighValueReturns hvr
LEFT JOIN 
    item i ON hvr.sr_item_sk = i.i_item_sk
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT ss_store_sk FROM store_sales ss WHERE ss.ss_item_sk = hvr.sr_item_sk LIMIT 1)
WHERE 
    (s.s_state IS NULL OR s.s_country = 'USA')
    AND (hvr.total_returned / NULLIF(hvr.total_amount_refunded, 0)) < 10
ORDER BY 
    hvr.total_returned DESC
LIMIT 100
OFFSET 50;
