
WITH AddressWords AS (
    SELECT DISTINCT
        TRIM(REGEXP_REPLACE(ca_street_name, '[^A-Za-z0-9 ]', '')) AS word
    FROM customer_address
    WHERE ca_street_name IS NOT NULL
),
DemographicStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS num_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM customer_demographics
    GROUP BY cd_gender
),
FilteredDemographics AS (
    SELECT
        d.cd_gender,
        d.num_customers,
        d.avg_purchase_estimate,
        d.total_dependents,
        a.word
    FROM DemographicStats d
    JOIN AddressWords a ON LENGTH(a.word) BETWEEN 5 AND 10
)
SELECT
    fd.cd_gender,
    fd.num_customers,
    fd.avg_purchase_estimate,
    fd.total_dependents,
    STRING_AGG(DISTINCT fd.word, ', ') AS relevant_words
FROM FilteredDemographics fd
GROUP BY fd.cd_gender, fd.num_customers, fd.avg_purchase_estimate, fd.total_dependents
ORDER BY fd.cd_gender;
