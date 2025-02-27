
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_zip)) AS max_zip_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        SUM(cd_dep_count) AS total_dependencies,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_quantity) AS avg_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.avg_street_name_length,
    d.cd_gender,
    d.total_customers,
    d.total_dependencies,
    d.avg_purchase_estimate,
    s.total_sales,
    s.avg_quantity_sold
FROM 
    AddressStats a
JOIN 
    DemographicsStats d ON a.total_addresses > d.total_customers
JOIN 
    SalesStats s ON s.ws_bill_addr_sk = a.ca_address_sk
ORDER BY 
    a.total_addresses DESC, d.total_customers DESC;
