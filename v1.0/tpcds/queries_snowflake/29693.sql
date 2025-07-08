
WITH AddressAggregation AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS address_count,
        LISTAGG(ca_city, ', ') AS cities,
        LISTAGG(ca_street_name, ', ') AS street_names
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count,
        LISTAGG(DISTINCT cd_credit_rating, ', ') AS credit_ratings
    FROM customer_demographics
    GROUP BY cd_gender
),
FinalBenchmark AS (
    SELECT 
        aa.ca_state,
        aa.address_count,
        aa.cities,
        aa.street_names,
        cs.cd_gender,
        cs.max_purchase_estimate,
        cs.avg_dep_count,
        cs.credit_ratings
    FROM AddressAggregation aa
    JOIN CustomerStats cs ON 1=1
    ORDER BY aa.address_count DESC, cs.max_purchase_estimate DESC
)
SELECT 
    *
FROM FinalBenchmark
WHERE address_count > 5 AND max_purchase_estimate > 1000;
