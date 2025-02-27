
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, ca.ca_state
), ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_spent DESC) AS rank_value
    FROM 
        customer_data
), high_spenders AS (
    SELECT 
        c_state, 
        COUNT(*) AS high_spenders_count
    FROM 
        ranked_customers
    WHERE 
        rank_value <= 10
    GROUP BY 
        ca_state
)
SELECT 
    ca.ca_state,
    COALESCE(hs.high_spenders_count, 0) AS top_10_spenders,
    COUNT(c.c_customer_sk) AS total_customers,
    (COUNT(c.c_customer_sk) - COALESCE(hs.high_spenders_count, 0)) AS remaining_customers
FROM 
    customer_address ca
LEFT JOIN 
    high_spenders hs ON ca.ca_state = hs.c_state
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY 
    ca.ca_state
ORDER BY 
    ca.ca_state;
