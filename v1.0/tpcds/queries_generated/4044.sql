
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_marital_status
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    SUM(cs.total_spent) AS total_revenue,
    SUM(iss.total_sales) AS total_item_sales,
    AVG(cs.avg_order_value) AS avg_value_per_order,
    MAX(cs.gender_rank) AS max_gender_rank
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_stats cs ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    item_sales iss ON cs.c_customer_sk = iss.order_count
WHERE 
    ca.ca_state = 'CA'
    AND cs.total_orders > 5
GROUP BY 
    ca.ca_city
HAVING 
    SUM(iss.total_profit) > 1000
ORDER BY 
    unique_customers DESC
LIMIT 10;
