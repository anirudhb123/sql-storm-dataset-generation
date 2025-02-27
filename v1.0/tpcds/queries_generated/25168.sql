
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('NY', 'CA') AND cd.cd_dep_count > 1
),

item_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),

sales_per_customer AS (
    SELECT 
        rc.full_name,
        rc.ca_city,
        rc.ca_state,
        COALESCE(is.total_quantity, 0) AS total_quantity,
        COALESCE(is.total_profit, 0) AS total_profit
    FROM 
        ranked_customers rc
    LEFT JOIN 
        item_sales is ON rc.c_customer_id = is.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_quantity,
    total_profit
FROM 
    sales_per_customer
WHERE 
    city_rank <= 10
ORDER BY 
    ca_state, total_profit DESC;
