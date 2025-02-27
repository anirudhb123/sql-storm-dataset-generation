
WITH demographics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'O') AS marital_status,
        COALESCE(cd.cd_education_status, 'Unknown') AS education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
city_analysis AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(ss.total_net_profit) AS avg_net_profit_per_customer
    FROM 
        customer_address ca
    JOIN 
        demographics d ON ca.ca_address_sk = d.c_customer_sk
    JOIN 
        sales_summary ss ON d.c_customer_sk = ss.ws_bill_customer_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    d.full_name,
    d.gender,
    d.marital_status,
    d.education_status,
    ca.ca_city,
    ca.ca_state,
    coalesce(b.customer_count, 0) AS total_customers_in_city,
    coalesce(b.avg_net_profit_per_customer, 0) AS average_net_profit_per_customer
FROM 
    demographics d
LEFT JOIN 
    city_analysis b ON d.ca_city = b.ca_city
WHERE 
    d.gender = 'F' 
    AND d.marital_status = 'M'
ORDER BY 
    b.avg_net_profit_per_customer DESC
LIMIT 50;
