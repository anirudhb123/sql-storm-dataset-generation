
WITH customer_data AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        d.d_date AS first_purchase_date,
        da.ca_city AS address_city,
        da.ca_state AS address_state,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address da ON c.c_current_addr_sk = da.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
), 
processed_data AS (
    SELECT 
        c.c_customer_sk,
        c.full_name,
        c.first_purchase_date,
        c.address_city,
        c.address_state,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_purchase_estimate,
        CASE 
            WHEN c.cd_gender = 'M' THEN 'Mr. ' || c.full_name
            WHEN c.cd_gender = 'F' THEN 'Ms. ' || c.full_name
            ELSE c.full_name 
        END AS saluted_name,
        EXTRACT(YEAR FROM AGE(current_date, c.first_purchase_date)) AS years_since_first_purchase,
        CASE 
            WHEN c.address_city ILIKE '%New%' THEN 'New City Discount'
            ELSE 'Regular Customer' 
        END AS customer_category
    FROM 
        customer_data c
)
SELECT 
    address_city,
    address_state,
    COUNT(*) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT saluted_name, ', ') AS unique_customer_names
FROM 
    processed_data
GROUP BY 
    address_city, 
    address_state
ORDER BY 
    total_customers DESC, 
    avg_purchase_estimate DESC
LIMIT 10;
