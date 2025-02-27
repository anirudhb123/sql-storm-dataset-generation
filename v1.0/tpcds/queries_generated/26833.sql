
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ws_order_number IS NOT NULL THEN 'Web Sale'
            WHEN cs_order_number IS NOT NULL THEN 'Catalog Sale'
            WHEN ss_ticket_number IS NOT NULL THEN 'Store Sale'
            ELSE 'Unknown Sale'
        END AS sale_type,
        coalesce(ws_sold_date_sk, cs_sold_date_sk, ss_sold_date_sk) AS sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ws_bill_customer_sk,
        ws_ship_customer_sk
    FROM 
        web_sales
    FULL OUTER JOIN 
        catalog_sales ON ws_order_number = cs_order_number
    FULL OUTER JOIN 
        store_sales ON ws_order_number = ss_ticket_number
)
SELECT 
    a.full_address,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    s.sale_type,
    SUM(s.ws_quantity) AS total_quantity,
    SUM(s.ws_net_profit) AS total_net_profit
FROM 
    AddressDetails a
JOIN 
    CustomerInfo c ON a.ca_address_sk = c.c_customer_sk
JOIN 
    SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk OR c.c_customer_sk = s.ws_ship_customer_sk
GROUP BY 
    a.full_address, c.full_name, c.cd_gender, c.cd_marital_status, s.sale_type
ORDER BY 
    total_net_profit DESC, total_quantity DESC
LIMIT 100;
