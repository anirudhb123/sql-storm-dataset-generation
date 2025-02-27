
WITH AddressData AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_address
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemoData AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, '; ') AS education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        STRING_AGG(DISTINCT wp_type, ', ') AS web_page_types
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    JOIN 
        web_page ON ws_web_page_sk = wp_web_page_sk
    GROUP BY 
        d_year
)

SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.avg_purchase_estimate,
    d.education_statuses,
    s.d_year,
    s.total_sales,
    s.total_orders,
    s.web_page_types
FROM 
    AddressData a
JOIN 
    DemoData d ON a.address_count > 5
JOIN 
    SalesData s ON d.avg_purchase_estimate > 500
ORDER BY 
    s.total_sales DESC;
