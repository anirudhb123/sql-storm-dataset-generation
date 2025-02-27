
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        SUBSTRING(cd.cd_education_status, 1, 10) AS short_education_status,
        COALESCE(NULLIF(c.c_email_address, ''), 'No Email') AS effective_email,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status_desc
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM 
        web_sales ws
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    si.ws_sales_price,
    si.ws_quantity,
    si.net_profit,
    si.ws_order_number,
    CASE 
        WHEN si.sale_rank = 1 THEN 'Latest Sale'
        ELSE 'Earlier Sale'
    END AS sale_status
FROM 
    CustomerInfo ci
JOIN 
    SalesInfo si ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = si.ws_bill_customer_sk)
WHERE 
    ci.cd_gender = 'F' 
    AND ci.short_education_status LIKE 'High%'
ORDER BY 
    ci.ca_city, si.ws_sold_date_sk DESC;
