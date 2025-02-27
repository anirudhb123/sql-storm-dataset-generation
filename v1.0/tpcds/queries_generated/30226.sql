
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_sales,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_sales,
        level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_store_sk = sh.ss_store_sk
    WHERE 
        sh.level < 5
    GROUP BY 
        s.ss_store_sk
)
SELECT 
    ca_city, 
    ca_state,
    SUM(COALESCE(ws_net_profit, 0)) AS total_web_sales_profit,
    AVG(ws_net_paid) AS average_web_sales_amount,
    COUNT(DISTINCT c_customer_id) AS total_unique_customers,
    MAX(total_profit) AS max_store_profit,
    MIN(total_sales) AS min_store_sales
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    sales_hierarchy sh ON ss.ss_store_sk = sh.ss_store_sk
WHERE 
    ca_state IN ('CA', 'TX')
    AND ws_sold_date_sk IS NOT NULL
    AND (ws_net_profit IS NOT NULL OR ss_net_profit IS NOT NULL)
GROUP BY 
    ca_city, ca_state
HAVING 
    total_web_sales_profit > 10000
ORDER BY 
    total_unique_customers DESC, total_web_sales_profit DESC;
