WITH address_counts AS (
    SELECT ca_city, 
           ca_state, 
           COUNT(ca_address_sk) AS address_count, 
           STRING_AGG(ca_street_name, ', ' ORDER BY ca_street_number) AS street_names
    FROM customer_address
    GROUP BY ca_city, ca_state
), demographic_stats AS (
    SELECT cd_gender, 
           cd_marital_status, 
           AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
           SUM(cd_dep_count) AS total_dependents
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
), combined AS (
    SELECT a.ca_city, 
           a.ca_state, 
           a.address_count, 
           a.street_names, 
           d.cd_gender, 
           d.cd_marital_status, 
           d.avg_purchase_estimate, 
           d.total_dependents
    FROM address_counts a
    JOIN demographic_stats d ON a.ca_state = d.cd_gender 
)
SELECT ca_city, 
       ca_state, 
       address_count, 
       street_names, 
       cd_gender, 
       cd_marital_status, 
       avg_purchase_estimate, 
       total_dependents
FROM combined
WHERE address_count > 10
ORDER BY ca_state, avg_purchase_estimate DESC;