
WITH AddressSummary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),

CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS total_customers,
        STRING_AGG(CONCAT(cd_gender, '-', cd_marital_status), ', ') AS demographics_list
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),

SalesData AS (
    SELECT 
        t.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim t ON ws.ws_sold_date_sk = t.d_date_sk
    GROUP BY 
        t.d_year
)

SELECT 
    a.ca_city,
    a.ca_state,
    a.total_addresses,
    a.full_addresses,
    c.cd_gender,
    c.cd_marital_status,
    c.total_customers,
    c.demographics_list,
    s.d_year,
    s.total_sales,
    s.total_orders
FROM 
    AddressSummary a
CROSS JOIN 
    CustomerDemographics c
CROSS JOIN 
    SalesData s
ORDER BY 
    a.ca_city, c.cd_gender, s.d_year DESC;
