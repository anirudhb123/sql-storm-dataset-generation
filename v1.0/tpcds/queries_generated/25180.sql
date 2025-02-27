
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    c.customer_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    LENGTH(a.full_address) AS address_length,
    UPPER(c.customer_name) AS customer_name_upper,
    TRIM(c.cd_credit_rating) AS credit_rating_trimmed
FROM 
    AddressDetails a
JOIN 
    CustomerInfo c ON a.ca_zip = (
        SELECT DISTINCT ca_zip 
        FROM customer_address 
        WHERE ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = c.c_customer_sk)
    )
WHERE 
    c.cd_purchase_estimate > 1000
ORDER BY 
    LENGTH(a.full_address) DESC, 
    c.customer_name
LIMIT 100;
