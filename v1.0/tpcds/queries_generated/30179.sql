
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        s_store_name,
        1 AS level,
        SUM(ss_net_profit) AS total_net_profit
    FROM
        store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        s_store_sk, s_store_name

    UNION ALL

    SELECT
        sh.s_store_sk,
        sh.s_store_name,
        level + 1,
        SUM(ss.net_profit) AS total_net_profit
    FROM
        sales_hierarchy sh
    JOIN store_sales ss ON sh.s_store_sk = ss.ss_store_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        sh.s_store_sk, sh.s_store_name, level
),
sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
),
high_performance_customers AS (
    SELECT 
        * 
    FROM 
        sales_summary
    WHERE 
        rn <= 10
),
store_performance AS (
    SELECT 
        s_store_name,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS store_net_profit
    FROM 
        store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s_store_name
) 
SELECT 
    sh.s_store_name,
    sh.total_net_profit AS total_store_profit,
    sp.store_net_profit,
    COALESCE(SUM(hp.total_web_profit), 0) AS total_web_profit
FROM 
    sales_hierarchy sh
LEFT JOIN 
    store_performance sp ON sh.s_store_name = sp.s_store_name
LEFT JOIN 
    high_performance_customers hp ON hp.total_web_profit > 1000
WHERE 
    sh.level <= 2 
GROUP BY 
    sh.s_store_name, sh.total_net_profit, sp.store_net_profit
ORDER BY 
    total_store_profit DESC, total_web_profit DESC;
