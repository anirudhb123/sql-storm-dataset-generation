
WITH RECURSIVE ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
    UNION ALL
    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_net_profit IS NOT NULL
),
sales_summary AS (
    SELECT 
        s.ss_item_sk,
        COALESCE(s.sum_net_profit, 0) AS total_net_profit,
        COALESCE(c.customer_count, 0) AS total_customers
    FROM 
        (SELECT 
            ss_item_sk, 
            SUM(ss_net_profit) AS sum_net_profit 
         FROM 
            store_sales 
         WHERE 
            ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
         GROUP BY 
            ss_item_sk) s
    LEFT JOIN 
        (SELECT 
            ws_item_sk, 
            COUNT(DISTINCT ws_bill_customer_sk) AS customer_count
         FROM 
            web_sales 
         GROUP BY 
            ws_item_sk) c 
    ON s.ss_item_sk = c.ws_item_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid) > (SELECT AVG(total_spent) FROM (SELECT SUM(ws_net_paid) AS total_spent FROM web_sales GROUP BY ws_bill_customer_sk) avg_spent)
)
SELECT 
    a.ca_city,
    a.ca_state,
    ss.total_net_profit,
    tc.c_customer_id,
    tc.total_spent,
    dense_rank() OVER (PARTITION BY a.ca_city ORDER BY ss.total_net_profit DESC) AS city_rank
FROM 
    customer_address a
JOIN 
    sales_summary ss ON ss.ss_item_sk = ss_item_sk
JOIN 
    top_customers tc ON tc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk LIMIT 1)
WHERE 
    ss.total_net_profit > 0
ORDER BY 
    a.ca_city, ss.total_net_profit DESC;
