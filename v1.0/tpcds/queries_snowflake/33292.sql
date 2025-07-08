
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) AS level
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1 AND 30
    UNION ALL
    SELECT 
        ss.ss_item_sk,
        ss.ss_ticket_number AS cs_order_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        sh.level + 1
    FROM 
        store_sales ss
    JOIN 
        sales_hierarchy sh ON ss.ss_item_sk = sh.cs_item_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 1 AND 30
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
    MAX(ws.ws_sales_price) AS max_sales_price,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_hierarchy sh ON ws.ws_item_sk = sh.cs_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND sh.level < 5
GROUP BY 
    ca.ca_city, c.c_customer_sk, ws.ws_net_profit, ws.ws_net_paid_inc_tax, ws.ws_sales_price
HAVING 
    SUM(ws.ws_net_profit) > 5000
ORDER BY 
    total_net_profit DESC
LIMIT 10;
