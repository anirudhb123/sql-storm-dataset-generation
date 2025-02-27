
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        ca_address_sk
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CombinedDetails AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM CustomerDetails cd
    JOIN AddressDetails ad ON cd.ca_address_sk = ad.ca_address_sk
)
SELECT 
    c_first_name,
    c_last_name,
    full_address,
    ca_city,
    ca_state,
    COUNT(*) OVER () AS total_customers,
    AVG(cd_purchase_estimate) OVER () AS average_purchase_estimate,
    MAX(cd_purchase_estimate) OVER () AS max_purchase_estimate,
    MIN(cd_purchase_estimate) OVER () AS min_purchase_estimate
FROM CombinedDetails
WHERE cd_gender = 'F' AND cd_purchase_estimate > 1000
ORDER BY ca_city, c_last_name;
