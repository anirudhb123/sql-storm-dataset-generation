
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        1 AS level,
        0 AS total_spent,
        0 AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M'
    
    UNION ALL

    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_gender,
        sh.cd_marital_status,
        level + 1,
        COALESCE(so.total_spent, 0) + COALESCE(ws.total_spent, 0) AS total_spent,
        COALESCE(so.total_orders, 0) + COALESCE(ws.total_orders, 0) AS total_orders
    FROM 
        sales_hierarchy sh
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk AS c_customer_sk,
            SUM(ws_net_paid) AS total_spent,
            COUNT(DISTINCT ws_order_number) AS total_orders
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
    ) ws ON sh.c_customer_sk = ws.c_customer_sk
    LEFT JOIN (
        SELECT 
            ss_customer_sk AS c_customer_sk,
            SUM(ss_net_paid) AS total_spent,
            COUNT(DISTINCT ss_ticket_number) AS total_orders
        FROM 
            store_sales
        GROUP BY 
            ss_customer_sk
    ) so ON sh.c_customer_sk = so.c_customer_sk
    WHERE 
        sh.total_spent < 5000
)

SELECT 
    level,
    c.c_first_name,
    c.c_last_name,
    cd.cd_marital_status,
    s.total_spent,
    s.total_orders,
    RANK() OVER (PARTITION BY level ORDER BY s.total_spent DESC) AS spend_rank
FROM 
    sales_hierarchy s
JOIN 
    customer c ON s.c_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY 
    level, s.total_spent DESC
LIMIT 100;
