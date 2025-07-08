
WITH Address_Stats AS (
    SELECT
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(ca_street_name, ', ') AS street_names,
        LISTAGG(DISTINCT ca_zip, ', ') AS zip_codes
    FROM customer_address
    GROUP BY ca_city
),
Demographics_Aggregation AS (
    SELECT
        cd_gender,
        COUNT(*) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependent_count
    FROM customer_demographics
    GROUP BY cd_gender
)
SELECT
    a.ca_city,
    a.address_count,
    a.street_names,
    a.zip_codes,
    d.cd_gender,
    d.demo_count,
    d.avg_purchase_estimate,
    d.max_dependent_count
FROM Address_Stats a
JOIN Demographics_Aggregation d ON a.address_count = d.demo_count
WHERE a.address_count > 5
ORDER BY a.address_count DESC, d.avg_purchase_estimate DESC;
