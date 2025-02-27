
WITH FilteredCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
AddressStats AS (
    SELECT ca.ca_city, ca.ca_state, COUNT(*) AS address_count
    FROM customer_address ca
    JOIN FilteredCustomers fc ON ca.ca_address_sk = fc.c_current_addr_sk
    GROUP BY ca.ca_city, ca.ca_state
),
TopCities AS (
    SELECT ca.ca_city, ca.ca_state, address_count,
           RANK() OVER (PARTITION BY ca.ca_state ORDER BY address_count DESC) AS city_rank
    FROM AddressStats ca
)
SELECT city_rank, ca.ca_city, ca.ca_state, address_count
FROM TopCities ca
WHERE city_rank <= 3
ORDER BY ca.ca_state, city_rank;
