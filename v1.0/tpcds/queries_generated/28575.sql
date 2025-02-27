
WITH Address_City AS (
    SELECT DISTINCT ca.city AS address_city
    FROM customer_address ca
    WHERE ca.city IS NOT NULL
),
Customer_Demographics AS (
    SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
           COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
String_Analysis AS (
    SELECT ca.ca_state, 
           LENGTH(ca.ca_city) AS city_length,
           UPPER(ca.ca_city) AS city_upper,
           LOWER(ca.ca_city) AS city_lower,
           REPLACE(ca.ca_city, ' ', '') AS city_no_spaces,
           SUBSTRING(ca.ca_city, 1, 3) AS city_substring
    FROM customer_address ca
    WHERE ca.ca_city IN (SELECT address_city FROM Address_City)
),
Final_Benchmark AS (
    SELECT sa.ca_state, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status,
           SUM(cd.customer_count) AS total_customers,
           AVG(sa.city_length) AS avg_city_length,
           COUNT(sa.city_upper) AS result_count
    FROM String_Analysis sa
    JOIN Customer_Demographics cd ON sa.ca_state = (SELECT DISTINCT ca.ca_state FROM customer_address ca)
    GROUP BY sa.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    fb.ca_state, 
    fb.cd_gender, 
    fb.cd_marital_status, 
    fb.cd_education_status, 
    fb.total_customers, 
    fb.avg_city_length, 
    fb.result_count
FROM Final_Benchmark fb
ORDER BY fb.ca_state, fb.total_customers DESC;
