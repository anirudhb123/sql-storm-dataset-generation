
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
), enriched_sales AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.ca_zip,
        sd.total_quantity,
        sd.total_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    cd_gender AS gender,
    cd_marital_status AS marital_status,
    LOWER(ca_city) AS city,
    ca_state AS state,
    ca_country AS country,
    AVG(total_quantity) AS avg_quantity,
    AVG(total_sales) AS avg_sales,
    COUNT(*) AS customer_count
FROM 
    enriched_sales
WHERE 
    total_quantity IS NOT NULL
GROUP BY 
    cd_gender, cd_marital_status, ca_city, ca_state, ca_country
ORDER BY 
    avg_sales DESC, avg_quantity DESC;
