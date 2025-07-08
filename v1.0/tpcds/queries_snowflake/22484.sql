
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS ReturnRank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
MaxReturns AS (
    SELECT 
        sr_item_sk,
        MAX(ReturnRank) AS MaxRank
    FROM 
        RankedReturns
    GROUP BY 
        sr_item_sk
),
FilteredReturns AS (
    SELECT 
        r.* 
    FROM 
        RankedReturns r
    JOIN 
        MaxReturns m ON r.sr_item_sk = m.sr_item_sk AND r.ReturnRank = m.MaxRank
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd_credit_rating
        END AS credit_rating_null_handling
    FROM 
        customer_demographics 
    WHERE 
        cd_purchase_estimate > 2000
)
SELECT 
    DISTINCT c.c_customer_id,
    ca.ca_city, 
    SUM(f.sr_return_amt) AS total_return_amt,
    COUNT(DISTINCT f.sr_item_sk) AS unique_returned_items,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT cd.credit_rating_null_handling, ', ') WITHIN GROUP (ORDER BY cd.credit_rating_null_handling) AS distinct_credit_ratings,
    CASE 
        WHEN SUM(f.sr_return_amt) > 1000 THEN 'High Returner'
        WHEN SUM(f.sr_return_amt) BETWEEN 500 AND 1000 THEN 'Medium Returner'
        ELSE 'Low Returner'
    END AS returner_category
FROM 
    FilteredReturns f
JOIN 
    customer c ON f.sr_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    date_dim d ON f.sr_returned_date_sk = d.d_date_sk 
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31' 
    AND ca.ca_city IS NOT NULL
GROUP BY 
    c.c_customer_id, 
    ca.ca_city
ORDER BY 
    total_return_amt DESC, 
    c.c_customer_id ASC
LIMIT 100;
