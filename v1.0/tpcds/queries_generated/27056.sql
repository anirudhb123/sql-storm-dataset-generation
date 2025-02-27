
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk DESC) AS rn
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
AddressInfo AS (
    SELECT 
        a.ca_address_sk, 
        a.ca_city, 
        a.ca_state,
        STRING_AGG(DISTINCT CONCAT(a.ca_street_number, ' ', a.ca_street_name, ' ', a.ca_street_type), ', ') AS full_address
    FROM 
        RankedAddresses a
    WHERE 
        a.rn <= 3
    GROUP BY 
        a.ca_address_sk, a.ca_city, a.ca_state
),
CustomerEmails AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        e.ca_address_sk,
        e.full_address
    FROM 
        customer c
    JOIN 
        AddressInfo e ON c.c_current_addr_sk = e.ca_address_sk
    WHERE 
        c.c_email_address LIKE '%@%'
)
SELECT 
    ce.c_customer_sk,
    ce.c_email_address, 
    ARRAY_AGG(e.full_address) AS addresses
FROM 
    CustomerEmails ce
GROUP BY 
    ce.c_customer_sk, ce.c_email_address
HAVING 
    COUNT(e.full_address) > 1
ORDER BY 
    ce.c_customer_sk;
