
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, c.c_customer_id
),
top_customers AS (
    SELECT 
        web_site_id,
        c_customer_id,
        total_net_profit
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        th.total_net_profit
    FROM 
        top_customers AS th
    JOIN 
        customer AS c ON th.c_customer_id = c.c_customer_id
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.total_net_profit
FROM 
    customer_info AS ci
ORDER BY 
    ci.total_net_profit DESC;
