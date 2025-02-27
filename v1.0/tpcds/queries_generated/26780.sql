
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name, '; ') AS all_street_names,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS formatted_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT c_email_address, '; ') AS unique_emails,
        STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') AS full_names
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
ReturnStats AS (
    SELECT 
        sr_reason_sk,
        COUNT(sr_return_quantity) AS total_returns,
        STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') AS returning_customers
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        sr_reason_sk
)

SELECT 
    a.ca_city,
    a.address_count,
    a.all_street_names,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.unique_emails,
    c.full_names,
    r.total_returns,
    r.returning_customers
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.address_count > 10
JOIN 
    ReturnStats r ON r.total_returns > 5
ORDER BY 
    a.address_count DESC, c.customer_count DESC, r.total_returns DESC;
