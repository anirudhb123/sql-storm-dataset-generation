
WITH AddressData AS (
    SELECT
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(full_address) AS address_length
    FROM
        customer_address
),
CustomerDemographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM
        customer_demographics
),
AddressWithDemographics AS (
    SELECT
        ad.ca_address_id,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        AddressData ad
    JOIN
        customer c ON ad.ca_address_id = c.c_customer_id
    JOIN
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    full_address,
    ca_city,
    ca_state,
    COUNT(*) OVER () AS total_addresses,
    MAX(address_length) OVER () AS max_address_length,
    MAX(cd_purchase_estimate) AS max_purchase_estimate,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    GROUP_CONCAT(DISTINCT cd_gender) AS unique_genders,
    GROUP_CONCAT(DISTINCT cd_marital_status) AS unique_marital_statuses
FROM
    AddressWithDemographics
WHERE
    ca_state = 'CA'
GROUP BY
    full_address, ca_city, ca_state
ORDER BY
    total_addresses DESC, avg_purchase_estimate DESC;
