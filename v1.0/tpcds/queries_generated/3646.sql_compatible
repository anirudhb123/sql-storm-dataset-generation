
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.profit_rank <= 10
), 
customer_addresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_city) AS address_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.order_count,
    SUM(NULLIF(ca.address_rank, 0)) AS unique_address_count,
    STRING_AGG(DISTINCT CONCAT(ca.ca_city, ', ', ca.ca_state)) AS address_summary
FROM 
    top_customers tc
LEFT JOIN 
    customer_addresses ca ON tc.c_customer_sk = ca.c_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_profit, tc.order_count
ORDER BY 
    tc.total_profit DESC;
