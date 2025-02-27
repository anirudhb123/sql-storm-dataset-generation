
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk
    UNION ALL
    SELECT 
        sh.s_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales ss ON sh.s_store_sk = ss.s_store_sk AND ss.ss_sold_date_sk = sh.ss_sold_date_sk + 1
    GROUP BY 
        sh.s_store_sk, ss.ss_sold_date_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        (SUM(ws.ws_sales_price) - SUM(ws.ws_ext_discount_amt)) AS net_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    ca.ca_city,
    SUM(ch.total_net_profit) AS total_store_profit,
    SUM(cs.total_web_profit) AS total_web_profit,
    SUM(cs.total_catalog_profit) AS total_catalog_profit,
    ARRAY_AGG(DISTINCT i.i_item_desc) AS sold_item_descriptions,
    AVG(i.net_sales_price) AS avg_item_sales_price
FROM 
    customer_address ca
LEFT JOIN 
    sales_hierarchy ch ON ca.ca_address_sk = ch.s_store_sk
LEFT JOIN 
    customer_sales cs ON cs.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk LIMIT 1)
LEFT JOIN 
    item_sales i ON i.i_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_addr_sk = ca.ca_address_sk)
WHERE 
    ch.total_net_profit IS NOT NULL AND 
    cs.total_web_profit IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ch.total_net_profit) > 1000
ORDER BY 
    total_store_profit DESC
LIMIT 10;
