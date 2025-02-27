
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws_bill_customer_sk,
        ws_order_number,
        ws_ext_sales_price,
        ws_net_profit,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT max(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        ws.bill_customer_sk,
        ws.order_number,
        ws.ext_sales_price,
        ws.net_profit,
        sh.level + 1
    FROM web_sales ws
    INNER JOIN SalesHierarchy sh ON ws.bill_customer_sk = sh.ws_bill_customer_sk
    WHERE ws.ws_order_number <> sh.ws_order_number
)

SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(net_profit) AS total_net_profit,
    AVG(ws_ext_sales_price) AS average_sales_price,
    MIN(ws_ext_sales_price) AS min_sales_price,
    MAX(ws_ext_sales_price) AS max_sales_price,
    CASE 
        WHEN COUNT(DISTINCT ws_order_number) = 0 THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    SalesHierarchy sh ON sh.ws_order_number = ws.ws_order_number
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca_state
HAVING 
    total_customers > 0
ORDER BY 
    total_net_profit DESC
LIMIT 10;
