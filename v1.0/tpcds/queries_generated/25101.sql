
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_review_date,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_last_review_date_sk = d.d_date_sk
), FilteredCustomers AS (
    SELECT 
        full_name,
        last_review_date,
        cd_gender,
        ca_city,
        ca_state,
        ca_country
    FROM 
        CustomerInfo
    WHERE 
        last_review_date >= '2023-01-01' AND 
        cd_gender = 'M'
), ConcatenatedCities AS (
    SELECT 
        STRING_AGG(ca_city, ', ') AS cities,
        ca_state,
        ca_country
    FROM 
        FilteredCustomers
    GROUP BY 
        ca_state, ca_country
)
SELECT 
    ca_state,
    ca_country,
    COUNT(*) AS customer_count,
    STDEV(DATEDIFF(DAY, last_review_date, GETDATE())) AS days_since_last_review,
    cities
FROM 
    FilteredCustomers
JOIN 
    ConcatenatedCities ON FilteredCustomers.ca_state = ConcatenatedCities.ca_state 
    AND FilteredCustomers.ca_country = ConcatenatedCities.ca_country
GROUP BY 
    ca_state, ca_country, cities
ORDER BY 
    customer_count DESC, ca_country, ca_state;
