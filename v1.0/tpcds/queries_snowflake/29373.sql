
WITH CustomerAddressStats AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        LISTAGG(DISTINCT ca_city, ', ') WITHIN GROUP (ORDER BY ca_city) AS cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM
        customer_address
    GROUP BY
        ca_state
),
CustomerDemographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        LISTAGG(DISTINCT cd_education_status, ', ') WITHIN GROUP (ORDER BY cd_education_status) AS education_levels,
        SUM(cd_purchase_estimate) AS total_purchase,
        SUM(cd_dep_count) AS total_dependencies
    FROM
        customer_demographics
    GROUP BY
        cd_gender, cd_marital_status
),
AddressDemo AS (
    SELECT
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.cities,
        cd.education_levels,
        MAX(cd.total_purchase) AS max_purchase,
        AVG(cd.total_dependencies) AS avg_dependencies
    FROM
        CustomerAddressStats AS ca
    JOIN
        CustomerDemographics AS cd ON ca.ca_state = (
            CASE 
                WHEN cd.cd_gender = 'M' THEN 'CA' 
                ELSE 'NY' 
            END
        )
    GROUP BY
        ca.ca_state, cd.cd_gender, cd.cd_marital_status, ca.cities, cd.education_levels
)
SELECT 
    a.ca_state AS State,
    a.cd_gender AS Gender,
    a.cd_marital_status AS Marital_Status,
    a.cities AS Cities,
    a.education_levels AS Education,
    a.max_purchase AS Max_Purchase,
    a.avg_dependencies AS Avg_Dependencies
FROM 
    AddressDemo AS a
ORDER BY 
    a.ca_state, a.cd_gender;
