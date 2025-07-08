
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        customer AS c
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ss.ss_net_profit) > 1000
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        sh.total_profit + SUM(ss.ss_net_profit) AS total_profit,
        sh.level + 1 AS level
    FROM 
        SalesHierarchy AS sh
    JOIN 
        customer AS c ON c.c_customer_sk = sh.c_customer_sk
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        sh.level < 5
    GROUP BY 
        c.c_customer_sk, sh.total_profit, sh.level
),
BestSellingItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales AS ws
    INNER JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    sh.total_profit,
    i.i_item_desc,
    bsi.total_quantity
FROM 
    customer AS c 
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    SalesHierarchy AS sh ON c.c_customer_sk = sh.c_customer_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    BestSellingItems AS bsi ON ws.ws_item_sk = bsi.ws_item_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    sh.total_profit > 5000
AND 
    ca.ca_city IS NOT NULL
ORDER BY 
    sh.total_profit DESC, bsi.total_quantity DESC;
