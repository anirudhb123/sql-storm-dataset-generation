
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
ranked_customers AS (
    SELECT 
        ci.*, 
        ss.total_profit,
        ss.total_orders,
        DENSE_RANK() OVER (ORDER BY ss.total_profit DESC) AS profit_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_id = ss.customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_zip,
    total_profit,
    total_orders,
    profit_rank
FROM 
    ranked_customers
WHERE 
    profit_rank <= 10
ORDER BY 
    total_profit DESC;
