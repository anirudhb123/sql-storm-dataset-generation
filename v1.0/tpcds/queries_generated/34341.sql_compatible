
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        0 AS level
    FROM 
        store
    WHERE 
        s_store_sk IS NOT NULL
    UNION ALL
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        level + 1
    FROM 
        SalesHierarchy
    WHERE 
        level < 5
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
    HAVING 
        COUNT(c.c_customer_sk) > 0
)
SELECT 
    sh.s_store_name,
    ci.ca_city,
    ci.ca_state,
    SUM(cs.total_profit) AS total_profit,
    AVG(cs.total_orders) AS avg_orders,
    CASE 
        WHEN AVG(cs.total_orders) IS NULL THEN 'No sales'
        WHEN AVG(cs.total_orders) > 10 THEN 'High activity'
        ELSE 'Low activity'
    END AS activity_level
FROM 
    SalesHierarchy sh
LEFT JOIN 
    CustomerSales cs ON sh.s_store_sk = cs.c_customer_id
JOIN 
    AddressInfo ci ON cs.c_customer_id IN (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk = ci.ca_address_id)
GROUP BY 
    sh.s_store_name, ci.ca_city, ci.ca_state
ORDER BY 
    total_profit DESC, avg_orders DESC;
