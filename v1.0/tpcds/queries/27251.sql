
WITH Address_Processing AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name)) AS address_length,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_country) AS lower_country
    FROM
        customer_address
),
Demo_Processing AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, '-', cd_marital_status) AS demographic_key,
        (SELECT  
            COUNT(*) 
         FROM 
            customer 
         WHERE 
            c_current_cdemo_sk = cd_demo_sk) AS customer_count
    FROM
        customer_demographics
),
Sales_Processing AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_sales_price) AS total_sales_amount,
        MIN(ws_sold_date_sk) AS first_sale_date,
        MAX(ws_sold_date_sk) AS last_sale_date
    FROM
        web_sales
    GROUP BY
        ws_item_sk
)
SELECT
    ap.full_address,
    ap.ca_city,
    ap.ca_state,
    dp.demographic_key,
    dp.customer_count,
    sp.total_sales_quantity,
    sp.total_sales_amount,
    sp.first_sale_date,
    sp.last_sale_date
FROM
    Address_Processing ap
JOIN
    Demo_Processing dp ON dp.cd_demo_sk IN (
        SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ap.ca_address_sk
    )
LEFT JOIN
    Sales_Processing sp ON sp.ws_item_sk IN (
        SELECT cs_item_sk FROM catalog_sales cs WHERE cs.cs_order_number IN (
            SELECT sr_ticket_number FROM store_returns sr WHERE sr.sr_addr_sk = ap.ca_address_sk
        )
    )
WHERE
    ap.address_length > 50
    AND dp.customer_count > 0
ORDER BY
    ap.ca_city, dp.customer_count DESC;
