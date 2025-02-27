
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) AS rank
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY', 'TX')
), ConcatenatedAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_name, ', ', ca_city, ', ', ca_state) AS full_address
    FROM RankedAddresses
    WHERE rank <= 3
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN ConcatenatedAddress ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COUNT(DISTINCT ca.full_address) AS address_count,
    STRING_AGG(ca.full_address, '; ') AS addresses
FROM CustomerDetails cd
JOIN ConcatenatedAddress ca ON cd.c_customer_sk = ca.ca_address_sk
GROUP BY cd.full_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
HAVING COUNT(DISTINCT ca.full_address) > 1
ORDER BY cd.cd_purchase_estimate DESC
LIMIT 10;
