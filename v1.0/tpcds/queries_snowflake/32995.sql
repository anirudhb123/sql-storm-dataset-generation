
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year
    HAVING 
        SUM(ws.ws_net_profit) > 1000

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        sh.total_profit
    FROM 
        SalesHierarchy sh
    JOIN 
        customer c ON c.c_customer_sk = sh.c_customer_sk
    WHERE 
        c.c_birth_year < (sh.c_birth_year - 1)
)

SELECT 
    s.c_first_name,
    s.c_last_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COALESCE(MAX(p.p_discount_active), 'N') AS active_discount,
    ROUND(SUM(ws.ws_ext_sales_price), 2) AS total_sales
FROM 
    SalesHierarchy s
LEFT JOIN 
    web_sales ws ON s.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN 
    store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
WHERE 
    EXTRACT(YEAR FROM DATE '2002-10-01') - s.c_birth_year <= 30
GROUP BY 
    s.c_first_name, s.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 10;
