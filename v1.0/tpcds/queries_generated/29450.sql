
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ship_customer_sk
)
SELECT 
    cd.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    sd.total_quantity,
    sd.total_sales,
    sd.order_count,
    CASE 
        WHEN sd.total_sales > 1000 THEN 'High Value'
        WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerDetails cd
JOIN 
    customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN 
    AddressDetails ad ON ca.ca_address_sk = ad.ca_address_sk
LEFT JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ship_customer_sk
ORDER BY 
    sd.total_sales DESC;
