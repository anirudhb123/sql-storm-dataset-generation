
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_country AS country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PromotionDetails AS (
    SELECT 
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        p.p_start_date_sk AS start_date_sk,
        p.p_end_date_sk AS end_date_sk
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
),
SalesData AS (
    SELECT 
        ws.ws_order_number AS order_number,
        ws.ws_sales_price AS sales_price,
        ws.ws_ship_date_sk AS ship_date_sk,
        ws.ws_web_page_sk AS web_page_sk,
        c.full_name AS customer_name,
        COALESCE(p.promo_name, 'No Promotion') AS promo_name
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails c ON ws.ws_bill_customer_sk = c.customer_sk
    LEFT JOIN 
        PromotionDetails p ON ws.ws_promo_sk = p.p_promo_sk
),
StringBenchmark AS (
    SELECT 
        customer_name,
        promo_name,
        ship_date_sk,
        sales_price,
        LENGTH(customer_name) AS name_length,
        LENGTH(promo_name) AS promo_length,
        REPLACE(promo_name, ' ', '') AS promo_without_spaces
    FROM 
        SalesData
    WHERE 
        ship_date_sk BETWEEN CAST('2022-01-01' AS DATE) AND CAST('2022-12-31' AS DATE)
)
SELECT 
    customer_name,
    promo_name,
    sales_price,
    name_length,
    promo_length,
    promo_without_spaces
FROM 
    StringBenchmark
ORDER BY 
    name_length DESC, promo_length DESC;
