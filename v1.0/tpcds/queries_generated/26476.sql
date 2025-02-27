
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_address_sk,
        ca_country
    FROM 
        customer_address 
    WHERE 
        ca_country LIKE '%United States%'
),
FilteredDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics 
    WHERE 
        cd_purchase_estimate > 1000
),
AddressDemographics AS (
    SELECT 
        ad.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        AddressDetails ad
    JOIN 
        customer c ON ad.ca_address_sk = c.c_current_addr_sk
    JOIN 
        FilteredDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ad.full_address,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM 
        AddressDemographics ad
    JOIN 
        web_sales ws ON ad.full_address LIKE CONCAT('%', ws.ws_ship_addr_sk, '%')
    GROUP BY 
        ad.full_address
)
SELECT 
    a.full_address,
    a.total_orders,
    a.total_sales,
    a.avg_order_value,
    ad.cd_gender,
    ad.cd_marital_status,
    ad.cd_education_status
FROM 
    SalesSummary a
JOIN 
    AddressDemographics ad ON a.full_address = ad.full_address
ORDER BY 
    a.total_sales DESC
LIMIT 100;
