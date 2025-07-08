
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_marital_status,
    ch.cd_gender,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM 
    customer_hierarchy ch
LEFT JOIN 
    web_sales ws ON ch.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) 
                                 FROM date_dim 
                                 WHERE d_year = 2023) 
                          - 30 AND (SELECT MAX(d_date_sk) 
                                     FROM date_dim 
                                     WHERE d_year = 2023)
GROUP BY 
    ch.c_customer_sk, 
    ch.c_first_name, 
    ch.c_last_name, 
    ch.cd_marital_status, 
    ch.cd_gender
HAVING 
    AVG(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) 
                              FROM web_sales ws2 
                              WHERE ws2.ws_sold_date_sk >= (SELECT MIN(d_date_sk) 
                                                               FROM date_dim 
                                                               WHERE d_year = 2023)
                              AND ws2.ws_sold_date_sk <= (SELECT MAX(d_date_sk) 
                                                            FROM date_dim 
                                                            WHERE d_year = 2023))
ORDER BY 
    avg_net_profit DESC
LIMIT 10;
