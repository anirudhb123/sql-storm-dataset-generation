
WITH RankedAddresses AS (
    SELECT 
        ca.city,
        ca.state,
        COUNT(*) AS address_count,
        ROW_NUMBER() OVER (PARTITION BY ca.city ORDER BY COUNT(*) DESC) AS rank_within_city
    FROM customer_address ca
    WHERE ca.country = 'USA'
    GROUP BY ca.city, ca.state
),
LongStreetNames AS (
    SELECT 
        ca.city,
        ca.state,
        ca.street_name,
        LENGTH(ca.street_name) AS street_name_length
    FROM customer_address ca
    WHERE LENGTH(ca.street_name) > 30
),
AddressDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ra.city,
    ra.state,
    ra.address_count,
    ls.street_name,
    ls.street_name_length,
    ad.cd_gender,
    ad.cd_marital_status,
    ad.customer_count,
    ad.avg_purchase_estimate
FROM RankedAddresses ra
JOIN LongStreetNames ls ON ra.city = ls.city AND ra.state = ls.state
JOIN AddressDemographics ad ON ad.cd_gender IN ('M', 'F')
WHERE ra.rank_within_city = 1
ORDER BY ra.address_count DESC, ls.street_name_length DESC;
