
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        d.d_date AS sold_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    si.sold_date,
    SUM(si.ws_sales_price * si.ws_quantity) AS total_sales,
    COUNT(si.ws_order_number) AS order_count
FROM 
    CustomerDetails ci
JOIN 
    AddressInfo ai ON ci.c_customer_id IN (
        SELECT 
            c_customer_id
        FROM 
            customer
        WHERE 
            c_current_addr_sk IN (
                SELECT 
                    ca_address_sk
                FROM 
                    customer_address
                WHERE 
                    ca_city = ai.ca_city AND ca_state = ai.ca_state AND ca_zip = ai.ca_zip
            )
    )
JOIN 
    SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
GROUP BY 
    ci.full_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ai.full_address, 
    si.sold_date
HAVING 
    SUM(si.ws_sales_price * si.ws_quantity) > 1000
ORDER BY 
    total_sales DESC;
