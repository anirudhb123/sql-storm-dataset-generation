
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        ca_zip
    FROM
        customer_address
), DemographicDetails AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT('Income: ', ib_lower_bound, ' - ', ib_upper_bound) AS income_band,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM
        customer_demographics
    JOIN
        household_demographics ON cd_demo_sk = hd_demo_sk
    JOIN
        income_band ON hd_income_band_sk = ib_income_band_sk
), CombinedDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.income_band,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count
    FROM
        customer c
    JOIN
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN
        DemographicDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
), BenchmarkingData AS (
    SELECT
        full_name,
        full_address,
        ca_city,
        ca_state,
        ca_zip,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        income_band,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        LENGTH(full_address) AS address_length,
        LENGTH(full_name) AS name_length,
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital
    FROM
        CombinedDetails
    ORDER BY
        address_length DESC
    LIMIT 100
)
SELECT
    *,
    CASE 
        WHEN cd_dep_employed_count > 0 THEN (cd_dep_employed_count * 100.0 / NULLIF(cd_dep_count, 0))
        ELSE 0
    END AS employed_percentage
FROM
    BenchmarkingData;
