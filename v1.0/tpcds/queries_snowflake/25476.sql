
WITH RankedCustomers AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressStats AS (
    SELECT ca.ca_address_sk,
           ca.ca_city,
           ca.ca_state,
           COUNT(c.c_customer_sk) AS customer_count,
           LISTAGG(DISTINCT R.full_name, ', ') WITHIN GROUP (ORDER BY R.full_name) AS customer_names
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN RankedCustomers R ON c.c_customer_sk = R.c_customer_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT a.ca_city, 
       a.ca_state, 
       a.customer_count, 
       a.customer_names
FROM AddressStats a
WHERE a.customer_count >= 5
ORDER BY a.customer_count DESC;
