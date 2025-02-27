
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),

CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_bill_customer_sk,
        ws.ws_ship_date_sk
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk BETWEEN 20230101 AND 20231231
),

FinalSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        s.ws_order_number,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_sales_price * s.ws_quantity) AS total_sales
    FROM CustomerInfo c
    JOIN AddressInfo a ON a.ca_address_id = c.c_customer_id
    JOIN SalesInfo s ON s.ws_bill_customer_sk = c.c_customer_id
    GROUP BY 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        s.ws_order_number
)

SELECT 
    customer_id,
    first_name,
    last_name,
    full_address,
    MAX(total_quantity) AS max_quantity,
    SUM(total_sales) AS overall_sales
FROM FinalSummary
GROUP BY 
    customer_id,
    first_name,
    last_name,
    full_address
ORDER BY overall_sales DESC
LIMIT 10;
