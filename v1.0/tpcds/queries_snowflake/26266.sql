
WITH Address_Stats AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM
        customer_address
    GROUP BY
        ca_state
),
Customer_and_Address AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LENGTH(ca.ca_street_name) AS street_name_length
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_birth_year >= 1980
),
String_Benchmark AS (
    SELECT
        c.ca_state,
        LISTAGG(DISTINCT c.ca_city, ', ') WITHIN GROUP (ORDER BY c.ca_city) AS cities,
        LISTAGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, '; ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name) AS full_names,
        MAX(street_name_length) AS longest_street_name,
        MIN(street_name_length) AS shortest_street_name,
        a.unique_addresses
    FROM
        Customer_and_Address c
    JOIN
        Address_Stats a ON c.ca_state = a.ca_state
    GROUP BY
        c.ca_state, a.unique_addresses
)
SELECT
    *,
    'State: ' || ca_state || ' | Cities: ' || cities || ' | Longest Name: ' || longest_street_name || ' | Shortest Name: ' || shortest_street_name AS summary
FROM
    String_Benchmark
ORDER BY
    unique_addresses DESC;
