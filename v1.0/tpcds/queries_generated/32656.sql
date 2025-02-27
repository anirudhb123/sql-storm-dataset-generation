
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        s_store_sk

    UNION ALL

    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        sh.level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    JOIN 
        store_sales ss ON ss.ss_store_sk = sh.s_store_sk
    WHERE
        sh.total_net_profit > 0
    GROUP BY 
        s.s_store_sk, sh.level
),
best_selling_items AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20220131
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM 
        customer_info c
    JOIN 
        web_sales ws ON c.c_customer_id = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    s_store_sk,
    total_net_profit,
    total_sales,
    si.ws_item_sk AS best_selling_item,
    si.total_quantity AS best_selling_quantity,
    SUM(ss.total_spent) AS total_spent_by_customer
FROM 
    sales_hierarchy sh
LEFT JOIN 
    best_selling_items si ON TRUE
JOIN 
    sales_summary ss ON ss.c_customer_id = (SELECT MIN(c_customer_id) FROM customer_info)
GROUP BY 
    s_store_sk, total_net_profit, total_sales, si.ws_item_sk, si.total_quantity
HAVING 
    total_net_profit > 1000 AND total_sales > 10
ORDER BY 
    total_spent_by_customer DESC
LIMIT 10;
