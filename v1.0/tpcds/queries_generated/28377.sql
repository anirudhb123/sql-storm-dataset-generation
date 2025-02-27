
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
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
),
sales_summary AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
web_sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
combined_sales AS (
    SELECT 
        customer_details.c_customer_id,
        COALESCE(ss.total_profit, 0) + COALESCE(wss.total_profit, 0) AS overall_profit,
        ss.total_orders + wss.total_orders AS overall_orders,
        customer_details.cd_gender,
        customer_details.cd_marital_status,
        customer_details.cd_education_status,
        customer_details.ca_city,
        customer_details.ca_state,
        customer_details.ca_country
    FROM 
        customer_details
    LEFT JOIN 
        sales_summary ss ON customer_details.c_customer_id = ss.cs_bill_customer_sk
    LEFT JOIN 
        web_sales_summary wss ON customer_details.c_customer_id = wss.ws_bill_customer_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(overall_profit) AS average_profit,
    SUM(overall_orders) AS total_orders,
    ca_city,
    ca_state,
    ca_country
FROM 
    combined_sales
GROUP BY 
    cd_gender, 
    cd_marital_status, 
    ca_city, 
    ca_state, 
    ca_country
ORDER BY 
    total_orders DESC
LIMIT 10;
