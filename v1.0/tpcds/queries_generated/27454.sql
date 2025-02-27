
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS registration_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        (SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt)) AS net_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned_quantity,
        SUM(sr.sr_return_amt) AS total_returned_amount
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
PerformanceMetrics AS (
    SELECT 
        c.c_customer_id,
        c.full_name,
        a.full_address,
        SUM(s.total_quantity_sold) AS total_sales_quantity,
        SUM(s.total_sales_amount) AS total_sales_value,
        COALESCE(SUM(r.total_returned_quantity), 0) AS total_returned_quantity,
        COALESCE(SUM(r.total_returned_amount), 0) AS total_returned_value,
        ((SUM(s.total_sales_amount) - COALESCE(SUM(r.total_returned_amount), 0)) / NULLIF(SUM(s.total_sales_amount), 0)) * 100 AS net_sales_percentage
    FROM CustomerDetails c
    JOIN AddressDetails a ON a.ca_address_id = c.c_customer_id
    LEFT JOIN SalesData s ON s.ws_item_sk = c.c_customer_id
    LEFT JOIN ReturnData r ON r.sr_item_sk = c.c_customer_id
    GROUP BY c.c_customer_id, c.full_name, a.full_address
)
SELECT * 
FROM PerformanceMetrics
ORDER BY net_sales_percentage DESC
LIMIT 100;
