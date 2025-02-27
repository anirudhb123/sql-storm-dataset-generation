
WITH AddressDetails AS (
    SELECT 
        ca.city AS address_city,
        ca.state AS address_state,
        COUNT(*) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS customer_names,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, ca.state
),
MaxCustomer AS (
    SELECT 
        address_city,
        address_state,
        customer_count,
        customer_names,
        avg_purchase_estimate,
        RANK() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM 
        AddressDetails
)
SELECT 
    address_city,
    address_state,
    customer_count,
    customer_names,
    avg_purchase_estimate
FROM 
    MaxCustomer
WHERE 
    city_rank <= 5 
ORDER BY 
    customer_count DESC;
