
WITH address_data AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END
        ) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
customer_data AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        ws.net_paid,
        ws.ship_customer_sk,
        ws.ship_addr_sk,
        ws_quantity
    FROM 
        web_sales ws
    JOIN 
        web_site ws_data ON ws.web_site_sk = ws_data.web_site_sk
),
returns_data AS (
    SELECT 
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        wr_returned_date_sk,
        wr_returning_customer_sk
    FROM 
        web_returns
)

SELECT 
    cd.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    sd.web_name, 
    SUM(sd.net_paid) AS total_sales,
    SUM(rd.wr_return_quantity) AS total_returns,
    COUNT(DISTINCT rd.wr_order_number) AS return_count,
    COUNT(DISTINCT sd.ws_order_number) AS sales_count
FROM 
    customer_data cd
JOIN 
    address_data ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    sales_data sd ON cd.c_customer_sk = sd.ship_customer_sk
LEFT JOIN 
    returns_data rd ON sd.ship_customer_sk = rd.wr_returning_customer_sk 
GROUP BY 
    cd.full_name, ad.full_address, ad.ca_city, ad.ca_state, sd.web_name
ORDER BY 
    total_sales DESC, return_count DESC;
