
WITH AddressParts AS (
    SELECT
        TRIM(SUBSTRING(ca_street_name, 1, POSITION(' ' IN ca_street_name) - 1)) AS street_prefix,
        TRIM(SUBSTRING(ca_street_name, POSITION(' ' IN ca_street_name) + 1)) AS street_suffix,
        ca_city,
        ca_state
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
CityProfile AS (
    SELECT
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT street_suffix) AS unique_street_suffixes
    FROM AddressParts
    GROUP BY ca_state
),
CustomerGender AS (
    SELECT
        cd_gender,
        COUNT(*) AS gender_count
    FROM customer_demographics
    GROUP BY cd_gender
),
CombinedData AS (
    SELECT
        a.ca_state,
        a.total_addresses,
        a.unique_street_suffixes,
        g.gender_count
    FROM CityProfile a
    LEFT JOIN CustomerGender g ON 1=1  -- Cross join to get all gender counts with all states
)
SELECT 
    ca_state,
    total_addresses,
    unique_street_suffixes,
    SUM(gender_count) FILTER (WHERE cd_gender = 'M') AS male_count,
    SUM(gender_count) FILTER (WHERE cd_gender = 'F') AS female_count
FROM CombinedData
GROUP BY ca_state, total_addresses, unique_street_suffixes
ORDER BY ca_state;
