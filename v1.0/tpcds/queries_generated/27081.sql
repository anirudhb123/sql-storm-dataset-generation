
WITH address_data AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            ELSE 'Female' 
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_addr_sk,
        DATE_FORMAT(dd.d_date, '%Y-%m-%d') AS ship_date,
        wc.w_warehouse_name,
        wc.w_city AS warehouse_city
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN warehouse wc ON ws.ws_warehouse_sk = wc.w_warehouse_sk
) 
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    cd.full_name,
    cd.gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    sd.ship_date,
    sd.warehouse_city,
    SUM(sd.ws_sales_price) AS total_sales
FROM address_data ad
JOIN customer_data cd ON ad.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = cd.c_customer_sk)
JOIN sales_data sd ON sd.ws_bill_customer_sk = cd.c_customer_sk
GROUP BY 
    ad.full_address, ad.ca_city, ad.ca_state, ad.ca_zip, ad.ca_country,
    cd.full_name, cd.gender, cd.cd_marital_status, cd.cd_education_status,
    sd.ship_date, sd.warehouse_city
ORDER BY total_sales DESC;
