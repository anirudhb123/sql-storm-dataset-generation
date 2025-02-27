
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_returned_amount
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
AddressStats AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS total_customers
    FROM 
        customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_returns,
    cs.total_returned_amount,
    as.full_address,
    as.ca_city,
    as.ca_state,
    as.total_customers
FROM 
    CustomerStats cs
JOIN AddressStats as ON cs.c_customer_sk = as.ca_address_sk
WHERE 
    cs.total_returns > 0
ORDER BY 
    cs.total_returned_amount DESC 
LIMIT 10;
