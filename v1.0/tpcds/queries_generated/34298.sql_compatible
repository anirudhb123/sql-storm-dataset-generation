
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459776 AND 2459778 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 1000
    UNION ALL
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit * 1.1 AS total_profit 
    FROM 
        SalesHierarchy sh
    JOIN 
        customer_address ca ON sh.c_customer_sk = ca.ca_address_sk 
    WHERE 
        ca.ca_state = 'CA' 
),
AggregatedSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit,
        ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY sh.total_profit DESC) AS profit_rank
    FROM 
        SalesHierarchy sh
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.total_profit,
    CASE 
        WHEN s.total_profit IS NULL THEN 'No Profit'
        WHEN s.profit_rank = 1 THEN 'Top Performer'
        ELSE 'Regular Performer' 
    END AS performance_category,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
    MAX(sm.sm_carrier) AS max_carrier
FROM 
    AggregatedSales s
LEFT JOIN 
    web_sales ws ON s.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY 
    s.c_customer_sk, s.c_first_name, s.c_last_name, s.total_profit, s.profit_rank
HAVING 
    COALESCE(SUM(ws.ws_quantity), 0) >= 100
ORDER BY 
    s.total_profit DESC;
