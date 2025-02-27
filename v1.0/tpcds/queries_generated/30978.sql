
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_net_profit,
        1 AS level
    FROM 
        store_sales 
    WHERE 
        ss_net_profit > 100.00
    
    UNION ALL
    
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        s.ss_net_profit * 1.1, 
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_store_sk = sh.ss_store_sk AND s.ss_item_sk = sh.ss_item_sk
    WHERE 
        sh.level < 5
),
total_sales AS (
    SELECT 
        sh.ss_store_sk,
        SUM(sh.ss_net_profit) AS total_profit
    FROM 
        store_sales sh
    GROUP BY 
        sh.ss_store_sk
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_spent,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_purchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cp.total_spent > 500.00
),
final_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.order_count,
        CASE 
            WHEN cs.order_count > 10 THEN 'Frequent'
            WHEN cs.order_count BETWEEN 5 AND 10 THEN 'Moderate'
            ELSE 'Rare'
        END AS purchase_frequency,
        th.total_profit
    FROM 
        high_value_customers cs
    LEFT JOIN 
        total_sales th ON cs.c_customer_sk = th.ss_store_sk
)
SELECT 
    fa.c_customer_sk,
    fa.total_spent,
    fa.order_count,
    fa.purchase_frequency,
    fa.total_profit,
    CASE 
        WHEN fa.total_profit IS NULL THEN 'No Profit Generated'
        ELSE 'Profit Generated'
    END AS profit_status
FROM 
    final_analysis fa
ORDER BY 
    fa.total_spent DESC;
