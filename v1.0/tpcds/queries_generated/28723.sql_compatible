
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender,
        ca_address_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ss_customer_sk,
        COUNT(ss_ticket_number) AS total_purchases,
        SUM(ss_net_paid) AS total_spent
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    COALESCE(sd.total_purchases, 0) AS total_purchases,
    COALESCE(sd.total_spent, 0) AS total_spent
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.ca_address_sk = ad.ca_address_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ss_customer_sk
WHERE 
    ad.ca_state = 'CA' 
    AND cd.cd_gender = 'F' 
ORDER BY 
    total_spent DESC, 
    total_purchases DESC
LIMIT 100;
