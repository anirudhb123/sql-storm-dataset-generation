
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        cd.full_name,
        cd.full_address,
        cd.ca_city,
        cd.ca_state
    FROM web_sales ws
    JOIN CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY ws.ws_order_number, cd.full_name, cd.full_address, cd.ca_city, cd.ca_state
)
SELECT 
    sd.ws_order_number,
    sd.full_name,
    sd.full_address,
    sd.ca_city,
    sd.ca_state,
    sd.total_sales,
    sd.total_quantity,
    CASE 
        WHEN sd.total_sales > 1000 THEN 'High Spending Customer'
        WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Spending Customer'
        ELSE 'Low Spending Customer'
    END AS customer_segment
FROM SalesDetails sd
WHERE sd.total_sales > 0
ORDER BY sd.total_sales DESC
LIMIT 100;
