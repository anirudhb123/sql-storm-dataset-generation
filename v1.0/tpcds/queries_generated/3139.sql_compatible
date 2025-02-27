
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        SUM(rs.ws_quantity) AS total_quantity_sold,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        ranked_sales rs
    JOIN 
        customer_info ci ON rs.bill_customer_sk = ci.c_customer_sk
    WHERE 
        rs.rank <= 5
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.ca_city
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    COALESCE(ss.total_quantity_sold, 0) AS total_quantity,
    COALESCE(ss.total_net_profit, 0) AS total_profit
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.c_customer_sk
WHERE 
    ci.ca_city IS NOT NULL
ORDER BY 
    total_profit DESC;
