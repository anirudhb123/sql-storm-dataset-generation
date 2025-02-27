
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date >= DATEADD(YEAR, -1, GETDATE())
),
CityStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS customer_count,
        AVG(purchase_estimate) AS avg_purchase_estimate,
        SUM(dependent_count) AS total_dependents
    FROM 
        CustomerData
    GROUP BY 
        ca_city, ca_state
)
SELECT 
    ca_city,
    ca_state,
    customer_count,
    avg_purchase_estimate,
    total_dependents,
    CONCAT('City: ', ca_city, ', State: ', ca_state, ' - Customers: ', customer_count, ', Avg. Purchase Estimate: $', ROUND(avg_purchase_estimate, 2), ', Total Dependents: ', total_dependents) AS city_summary
FROM 
    CityStats
ORDER BY 
    total_dependents DESC, customer_count DESC
LIMIT 10;
