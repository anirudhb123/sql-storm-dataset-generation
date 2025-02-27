
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        1 AS hierarchy_level,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        store s
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.hierarchy_level + 1,
        SUM(ws.ws_net_profit) 
    FROM 
        sales_hierarchy sh
    JOIN store s ON s.s_store_sk = sh.s_store_sk
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        sh.s_store_sk, sh.s_store_name, sh.hierarchy_level
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
max_income AS (
    SELECT 
        hd.hd_income_band_sk,
        MAX(hd.hd_buy_potential) AS max_buy_potential
    FROM 
        household_demographics hd
    WHERE 
        hd_hd_dep_count > 0
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    s.s_store_name,
    sh.hierarchy_level,
    cs.gender,
    cs.total_orders,
    cs.total_spent,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    max_buy_potential
FROM 
    sales_hierarchy sh
JOIN customer_stats cs ON sh.s_store_sk = cs.c_customer_sk
JOIN income_band ib ON cs.total_spent BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
LEFT JOIN max_income mi ON ib.ib_income_band_sk = mi.hd_income_band_sk
WHERE 
    cs.total_orders > 10 AND
    sh.total_profit IS NOT NULL
ORDER BY 
    sh.total_profit DESC, 
    cs.total_spent DESC;
