
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        1 AS level
    FROM store s
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY s.s_store_sk, s.s_store_name
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        COALESCE(SUM(ws.ws_net_profit), 0) + sh.total_net_profit AS total_net_profit,
        sh.level + 1
    FROM sales_hierarchy sh
    JOIN store s ON sh.s_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    WHERE sh.level < 10
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status
),
profit_summary AS (
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sh.total_net_profit DESC) AS profit_rank,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
        AVG(cs.cs_net_paid) AS avg_catalog_sale
    FROM sales_hierarchy sh
    LEFT JOIN catalog_sales cs ON sh.s_store_sk = cs.cs_ship_mode_sk
    GROUP BY sh.s_store_sk, sh.s_store_name, sh.total_net_profit
)
SELECT 
    cs.full_name,
    cs.marital_status,
    ps.s_store_name,
    ps.total_net_profit,
    ps.total_catalog_sales,
    ps.avg_catalog_sale
FROM customer_summary cs
JOIN profit_summary ps ON cs.total_net_spent > ps.total_net_profit
WHERE cs.total_orders > 5
ORDER BY ps.total_net_profit DESC, cs.full_name ASC
LIMIT 100 OFFSET 0;
