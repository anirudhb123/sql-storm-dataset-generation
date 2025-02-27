
WITH Address_City AS (
    SELECT 
        ca_address_sk,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
Sales_Data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_sales) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        (SELECT 
            ws_item_sk,
            ws_net_paid_inc_tax AS ws_net_sales 
         FROM 
            web_sales) AS ws ON web_sales.ws_item_sk = ws.ws_item_sk
    GROUP BY 
        ws_item_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        CONCAT(cd_gender, '-', cd_marital_status) AS demographic_info
    FROM 
        customer_demographics
)
SELECT 
    A.ca_city,
    D.demographic_info,
    SUM(SD.total_quantity) AS aggregate_quantity,
    SUM(SD.total_sales) AS aggregate_sales,
    SUM(SD.total_tax) AS aggregate_tax,
    COUNT(DISTINCT SD.total_orders) AS unique_orders
FROM 
    Address_City A
JOIN 
    Sales_Data SD ON A.ca_address_sk = SD.ws_item_sk
JOIN 
    Demographics D ON SD.ws_item_sk = D.cd_demo_sk
WHERE 
    A.ca_city IS NOT NULL
GROUP BY 
    A.ca_city, D.demographic_info
ORDER BY 
    aggregate_sales DESC, A.ca_city ASC;
