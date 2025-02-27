
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_id,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        wd.warehouse_name
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse wd ON c.c_current_addr_sk = wd.w_warehouse_sk
),
SalesRecords AS (
    SELECT 
        ws_order_number,
        SUM(ws_sales_price) AS total_sales_amount,
        COUNT(ws_order_number) AS total_items_sold 
    FROM web_sales 
    GROUP BY ws_order_number
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.c_customer_id,
        ad.full_address,
        sr.total_sales_amount,
        sr.total_items_sold,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM CustomerDetails cd
    JOIN AddressDetails ad ON cd.c_customer_id = ad.ca_address_id
    JOIN SalesRecords sr ON cd.c_customer_id = sr.ws_order_number
)
SELECT 
    full_name,
    c_customer_id,
    full_address,
    total_sales_amount,
    total_items_sold,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM FinalReport
WHERE total_sales_amount > 1000
ORDER BY total_sales_amount DESC;
