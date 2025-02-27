
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(ss_net_paid) AS total_sales,
        1 AS level
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        SUM(ss.net_profit) AS total_sales,
        sh.level + 1
    FROM 
        store_sales ss
    JOIN 
        SalesHierarchy sh ON ss.ss_store_sk = sh.s_store_sk
    WHERE 
        sh.level < 5  -- Limiting recursion to 5 levels deep
    GROUP BY 
        sh.s_store_sk, sh.s_store_name
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
PromotionsUsage AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_usage_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High' 
            ELSE 'Regular' 
        END AS customer_category
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_orders > 5
)
SELECT 
    sh.s_store_name,
    hs.customer_category,
    SUM(hs.total_spent) AS total_revenue,
    AVG(hs.total_orders) AS avg_orders,
    COUNT(DISTINCT hs.c_customer_sk) AS unique_customers
FROM 
    SalesHierarchy sh
JOIN 
    HighSpenders hs ON sh.s_store_sk = hs.c_customer_sk
LEFT JOIN 
    PromotionsUsage pu ON hs.total_orders > 0
WHERE 
    sh.total_sales > 500
GROUP BY 
    sh.s_store_name, hs.customer_category
ORDER BY 
    total_revenue DESC, avg_orders DESC;
