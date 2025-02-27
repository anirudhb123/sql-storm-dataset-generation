
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), ranked_orders AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY COUNT(ws_order_number) DESC) AS order_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), top_customers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ro.order_count
    FROM 
        customer_info ci
    JOIN 
        ranked_orders ro ON ci.c_customer_sk = ro.ws_bill_customer_sk
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    order_count,
    COUNT(DISTINCT ci.c_customer_sk) AS total_customers
FROM 
    top_customers ci
GROUP BY 
    full_name, ca_city, ca_state, ca_country, order_count
ORDER BY 
    order_count DESC;
