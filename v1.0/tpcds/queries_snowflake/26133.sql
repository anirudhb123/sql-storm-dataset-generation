
WITH AddressParts AS (
    SELECT DISTINCT
        ca_address_sk,
        TRIM(REGEXP_REPLACE(ca_street_name, '[^a-zA-Z0-9 ]', '')) AS cleaned_street_name,
        LENGTH(TRIM(REGEXP_REPLACE(ca_street_name, '[^a-zA-Z0-9 ]', ''))) AS street_name_length,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper
    FROM customer_address
),
DemographicsSummary AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
CombinedInfo AS (
    SELECT
        a.ca_address_sk,
        d.cd_gender,
        d.customer_count,
        d.avg_purchase_estimate,
        a.cleaned_street_name,
        a.street_name_length,
        a.city_lower,
        a.state_upper
    FROM AddressParts a
    JOIN DemographicsSummary d ON d.customer_count > 100  
)
SELECT
    ci.city_lower,
    ci.state_upper,
    SUM(ci.avg_purchase_estimate) AS total_avg_purchase,
    LISTAGG(ci.cleaned_street_name, ', ') AS aggregated_street_names,
    MAX(ci.street_name_length) AS max_street_name_length
FROM CombinedInfo ci
GROUP BY ci.city_lower, ci.state_upper
ORDER BY total_avg_purchase DESC;
