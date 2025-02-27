
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        LOWER(TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number))) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        SUBSTRING(c_email_address, POSITION('@' IN c_email_address) + 1) AS domain,
        cd_dep_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
)
SELECT 
    ac.full_address,
    sd.total_sales,
    cd.gender,
    cd.marital_status,
    COUNT(DISTINCT cd.customer_sk) AS unique_customers,
    COUNT(d.domain) AS email_domains
FROM 
    AddressComponents ac
LEFT JOIN 
    SalesData sd ON ac.ca_address_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerData cd ON cd.c_customer_sk IN (SELECT c_customer_sk FROM store_sales WHERE ss_item_sk = sd.ws_item_sk)
WHERE 
    ac.ca_state = 'NY' 
GROUP BY 
    ac.full_address, cd.gender, cd.marital_status, sd.total_sales
ORDER BY 
    sd.total_sales DESC, unique_customers DESC
LIMIT 100;
