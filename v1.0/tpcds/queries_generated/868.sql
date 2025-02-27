
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) as state_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
high_value_customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        SUM(sd.total_net_profit) AS total_profit
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_data sd ON cd.c_customer_sk = sd.ws.bill_customer_sk 
    WHERE 
        cd.state_rank <= 10
    GROUP BY 
        cd.c_customer_sk, cd.c_first_name, cd.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        high_value_customers c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
max_profit AS (
    SELECT 
        MAX(total_profit) AS max_profit_value
    FROM 
        top_customers
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    CASE 
        WHEN tc.total_profit IS NULL THEN 'No Purchases'
        WHEN tc.total_profit = mp.max_profit_value THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    top_customers tc
CROSS JOIN 
    max_profit mp
WHERE 
    tc.total_profit > 0
ORDER BY 
    tc.total_profit DESC;
