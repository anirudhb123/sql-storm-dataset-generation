
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        SUM(CASE 
            WHEN ca_city LIKE '%o%' THEN 1 
            ELSE 0 
        END) AS city_with_o_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents,
        MIN(cd_dep_count) AS min_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_customer_sk) AS unique_customers
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
)
SELECT 
    a.ca_state,
    a.address_count,
    a.city_with_o_count,
    a.avg_street_name_length,
    a.max_street_name_length,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.max_dependents,
    c.min_dependents,
    s.total_sales,
    s.unique_customers,
    d.d_date
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.address_count > 50
JOIN 
    SalesStats s ON a.address_count < s.unique_customers
JOIN 
    date_dim d ON d.d_date_sk = s.ws_sold_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    a.ca_state, c.cd_gender;
