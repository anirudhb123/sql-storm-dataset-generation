
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_purchase_estimate,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS sales_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
        AND cd.cd_purchase_estimate > 1000
),
item_sales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
web_sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_transactions
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    is.total_sales_quantity AS store_sales_quantity,
    ws.total_web_sales_quantity AS web_sales_quantity,
    is.total_transactions AS store_sales_transactions,
    ws.total_web_transactions AS web_sales_transactions
FROM 
    customer_info ci
LEFT JOIN 
    item_sales is ON is.ss_item_sk IN (SELECT ss.ss_item_sk FROM store_sales ss WHERE ss.ss_customer_sk = ci.c_customer_sk)
LEFT JOIN 
    web_sales_info ws ON ws.ws_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = ci.c_customer_sk)
ORDER BY 
    ci.full_name;
