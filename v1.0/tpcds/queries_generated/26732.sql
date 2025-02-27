
WITH AddressComponents AS (
    SELECT 
        ca_address_id,
        ca_street_number,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_location_type
    FROM customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM customer c
    JOIN AddressComponents a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        c.customer_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_item_sk) AS items_sold
    FROM web_sales ws
    JOIN CustomerDetails c ON ws.ws_bill_customer_sk = c.c_customer_id
    GROUP BY ws.ws_order_number, c.customer_name
)
SELECT 
    sd.ws_order_number,
    sd.customer_name,
    sd.total_sales,
    sd.items_sold,
    CASE 
        WHEN sd.total_sales > 1000 THEN 'High Value'
        WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY sd.customer_name ORDER BY sd.total_sales DESC) AS sales_rank
FROM SalesData sd
WHERE sd.total_sales IS NOT NULL
ORDER BY sd.total_sales DESC, sd.customer_name;
