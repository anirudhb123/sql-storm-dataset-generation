
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        1 AS level
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.web_name
    
    UNION ALL

    SELECT 
        ws.web_site_sk,
        CONCAT(sh.web_name, ' > ', ws.web_name),
        sh.total_net_profit + SUM(ws.ws_net_profit),
        sh.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesHierarchy sh ON ws.web_site_sk = sh.web_site_sk
    GROUP BY 
        ws.web_site_sk, ws.web_name, sh.total_net_profit, sh.web_name, sh.level
)

SELECT 
    sh.web_name, 
    sh.total_net_profit,
    RANK() OVER (ORDER BY sh.total_net_profit DESC) AS profit_rank,
    COALESCE(CASE 
        WHEN sh.total_net_profit > 1000 THEN 'High Profit'
        WHEN sh.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END, 'Unknown') AS profit_category
FROM 
    SalesHierarchy sh
WHERE 
    sh.total_net_profit IS NOT NULL
ORDER BY 
    sh.total_net_profit DESC
LIMIT 10;

SELECT 
    'Store Sales' AS source,
    ss.ss_item_sk,
    SUM(ss.ss_sales_price) AS total_sold
FROM 
    store_sales ss
GROUP BY 
    ss.ss_item_sk
HAVING 
    total_sold > 500

INTERSECT

SELECT 
    'Web Sales' AS source,
    ws.ws_item_sk,
    SUM(ws.ws_sales_price) AS total_sold
FROM 
    web_sales ws
GROUP BY 
    ws.ws_item_sk
HAVING 
    total_sold > 500;

SELECT 
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_country IS NOT NULL
GROUP BY 
    ca.ca_country
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 100
ORDER BY 
    avg_purchase_estimate DESC;
