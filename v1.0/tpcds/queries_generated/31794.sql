
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_cdemo_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_cdemo_sk
    HAVING 
        SUM(ss_net_profit) > 10000
), 
customer_addresses AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        ca_country 
    FROM 
        customer_address 
    WHERE 
        ca_state IS NOT NULL
), 
sales_with_demographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        sc.total_profit,
        sc.total_sales,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_cte sc ON c.c_customer_sk = sc.ss_cdemo_sk
    LEFT JOIN 
        customer_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(ws.ws_order_number) AS web_order_count,
    MAX(ws.ws_sold_date_sk) AS last_order_date,
    COALESCE(sc.total_profit, 0) AS store_total_profit,
    COALESCE(sc.total_sales, 0) AS store_total_sales,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
FROM 
    web_sales ws
JOIN 
    sales_with_demographics sc ON ws.ws_bill_cdemo_sk = sc.c_customer_sk
WHERE 
    ws.ws_net_profit >= 0
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    sc.store_total_profit,
    sc.store_total_sales
HAVING 
    SUM(ws.ws_net_profit) > 5000
UNION ALL
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    0 AS total_web_profit,
    0 AS web_order_count,
    NULL AS last_order_date,
    COALESCE(sc.total_profit, 0) AS store_total_profit,
    COALESCE(sc.total_sales, 0) AS store_total_sales,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY sc.total_profit DESC) AS rn
FROM 
    sales_with_demographics sc
JOIN 
    customer c ON c.c_customer_sk = sc.c_customer_sk
WHERE 
    sc.total_profit IS NOT NULL
ORDER BY 
    total_web_profit DESC, 
    store_total_profit DESC;
