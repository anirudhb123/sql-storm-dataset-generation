
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS Gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT(cd_demo_sk, '-', TRIM(cd_education_status)) AS DemoKey
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sales_price,
        ws.ws_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS TotalSales
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id, ws.ws_sales_price, ws.ws_quantity
),
JoinedData AS (
    SELECT 
        a.FullAddress,
        c.Gender,
        c.cd_marital_status,
        c.cd_purchase_estimate,
        s.web_site_id,
        s.TotalSales
    FROM 
        AddressData a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerDemographics c ON c.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        SalesData s ON c.c_customer_id = s.web_site_id
)
SELECT 
    FullAddress,
    Gender,
    cd_marital_status,
    cd_purchase_estimate,
    SUM(TotalSales) AS TotalSalesByAddress
FROM 
    JoinedData
GROUP BY 
    FullAddress, Gender, cd_marital_status, cd_purchase_estimate
ORDER BY 
    TotalSalesByAddress DESC
LIMIT 100;
