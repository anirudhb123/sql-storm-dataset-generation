
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerData AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id
)

SELECT 
    a.ca_state,
    a.address_count,
    a.full_addresses,
    c.cd_gender,
    c.customer_count,
    c.total_dependents,
    s.web_site_id,
    s.total_sales,
    s.avg_net_paid
FROM 
    AddressStats a
JOIN 
    CustomerData c ON a.address_count > 100
JOIN 
    SalesData s ON s.total_sales > 10000
ORDER BY 
    a.ca_state, c.customer_count DESC, s.total_sales DESC;
