
WITH CustomerInfo AS (
    SELECT c.c_customer_id, 
           c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
           ca.ca_city,
           ca.ca_state,
           ca.ca_country,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StringBenchmark AS (
    SELECT customer_full_name,
           LENGTH(customer_full_name) AS name_length,
           UPPER(customer_full_name) AS upper_case_name,
           LOWER(customer_full_name) AS lower_case_name,
           REPLACE(customer_full_name, ' ', '-') AS dash_replaced_name,
           SUBSTRING(customer_full_name FROM 1 FOR 10) AS name_substring,
           REGEXP_REPLACE(customer_full_name, '[aeiou]', '', 'g') AS without_vowels
    FROM CustomerInfo
)
SELECT ca.ca_city, 
       ca.ca_state, 
       ca.ca_country, 
       COUNT(*) AS total_customers,
       AVG(name_length) AS avg_name_length,
       COUNT(DISTINCT upper_case_name) AS unique_upper_names,
       COUNT(DISTINCT dash_replaced_name) AS unique_dash_replaced_names,
       MAX(name_length) AS max_name_length
FROM StringBenchmark sb
JOIN customer_address ca ON sb.customer_full_name LIKE '%' || ca.ca_city || '%'
GROUP BY ca.ca_city, ca.ca_state, ca.ca_country
ORDER BY total_customers DESC;
