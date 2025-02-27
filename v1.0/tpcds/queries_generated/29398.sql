
WITH Address_City AS (
    SELECT DISTINCT ca_city
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
Customer_Gender AS (
    SELECT DISTINCT cd_gender
    FROM customer_demographics
    WHERE cd_gender IS NOT NULL
),
Address_Stats AS (
    SELECT 
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS full_address,
        ca.city,
        LENGTH(ca.street_name) AS street_name_length
    FROM customer_address ca
    WHERE ca.city IN (SELECT city FROM Address_City)
),
Gender_Stats AS (
    SELECT 
        cd.gender,
        COUNT(cd.demo_sk) AS total_customers,
        AVG(cd.dep_count) AS avg_dependencies
    FROM customer_demographics cd
    WHERE cd.gender IN (SELECT gender FROM Customer_Gender)
    GROUP BY cd.gender
)
SELECT 
    CONCAT('Address: ', Address_Stats.full_address, ' | City: ', Address_Stats.city, 
           ' | Street Name Length: ', Address_Stats.street_name_length, 
           ' | Gender: ', Gender_Stats.gender, 
           ' | Total Customers: ', Gender_Stats.total_customers, 
           ' | Avg Dependencies: ', Gender_Stats.avg_dependencies) AS benchmark_result
FROM Address_Stats
JOIN Gender_Stats ON true
ORDER BY street_name_length DESC;
