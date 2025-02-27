
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS address_length
    FROM customer_address
),
CustomerUnder30 AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM customer c 
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE (d.d_year - c.c_birth_year) < 30
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.ca_country,
    COUNT(DISTINCT cu.c_customer_sk) AS num_customers_under_30,
    SUM(sd.total_quantity) AS total_sales_quantity,
    SUM(sd.total_profit) AS total_sales_profit
FROM AddressInfo ai
LEFT JOIN CustomerUnder30 cu ON cu.c_customer_sk IN (
    SELECT DISTINCT c_customer_sk 
    FROM store_sales 
    WHERE ss_addr_sk = ai.ca_address_sk
)
LEFT JOIN SalesData sd ON sd.ws_item_sk IN (
    SELECT DISTINCT ws_item_sk 
    FROM web_sales 
    WHERE ws_bill_addr_sk = ai.ca_address_sk
)
GROUP BY ai.full_address, ai.ca_city, ai.ca_state, ai.ca_zip, ai.ca_country
ORDER BY num_customers_under_30 DESC, total_sales_profit DESC;
