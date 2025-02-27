
WITH AddressParts AS (
    SELECT 
        ca_address_id,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        REPLACE(ca_city, ' ', '') AS city_cleaned,
        UPPER(ca_state) AS state_upper,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        REPLACE(c.c_email_address, '@example.com', '@domain.com') AS modified_email
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_net_profit > 0
)
SELECT 
    ap.full_address,
    cd.full_customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sd.ws_sales_price) AS total_sales_price,
    AVG(sd.ws_net_profit) AS avg_net_profit,
    COUNT(sd.ws_order_number) AS total_orders
FROM AddressParts ap
JOIN CustomerDetails cd ON cd.full_customer_name IS NOT NULL
JOIN SalesData sd ON sd.ws_order_number IS NOT NULL
GROUP BY 
    ap.full_address,
    cd.full_customer_name,
    cd.cd_gender,
    cd.cd_marital_status
HAVING AVG(sd.ws_net_profit) > 100
ORDER BY total_orders DESC;
