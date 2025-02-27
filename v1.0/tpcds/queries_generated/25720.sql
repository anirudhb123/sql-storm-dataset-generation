
WITH AddressDetails AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(CONCAT(cd_marital_status, ' ', cd_education_status), ', ') AS demographic_desc
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        STRING_AGG(DISTINCT CONCAT(ws_web_site_sk, ': ', ws_order_number), '; ') AS order_numbers
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
CombinedData AS (
    SELECT 
        ad.ca_state,
        ad.address_count,
        ad.full_address_list,
        dm.cd_gender,
        dm.demographic_count,
        dm.demographic_desc,
        sd.ws_ship_date_sk,
        sd.total_sales,
        sd.order_numbers
    FROM 
        AddressDetails ad
    JOIN 
        Demographics dm ON ad.address_count > 1000
    LEFT JOIN 
        SalesData sd ON sd.total_sales > 10000
)
SELECT 
    ca_state,
    address_count,
    full_address_list,
    cd_gender,
    demographic_count,
    demographic_desc,
    ws_ship_date_sk,
    total_sales,
    order_numbers
FROM 
    CombinedData
ORDER BY 
    address_count DESC, total_sales DESC;
