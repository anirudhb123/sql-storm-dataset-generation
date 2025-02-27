
WITH AddressData AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
DemographicData AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerAddress AS (
    SELECT 
        c.c_customer_id,
        d.full_address,
        d.ca_city,
        d.ca_state,
        d.ca_country,
        demo.gender_marital_status,
        demo.education_status,
        demo.purchase_estimate_band,
        s.total_quantity,
        s.total_sales
    FROM 
        customer c
    JOIN 
        AddressData d ON c.c_current_addr_sk = d.ca_address_id
    JOIN 
        DemographicData demo ON c.c_current_cdemo_sk = demo.cd_demo_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_item_sk
)
SELECT 
    ca_city,
    ca_state,
    purchase_estimate_band,
    COUNT(*) AS customer_count,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_sales) AS total_sales_amount
FROM 
    CustomerAddress
GROUP BY 
    ca_city, ca_state, purchase_estimate_band
ORDER BY 
    ca_city, total_sales_amount DESC;
