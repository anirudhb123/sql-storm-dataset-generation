
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk, 
        ss_item_sk, 
        SUM(ss_quantity) AS total_sales_quantity,
        SUM(ss_net_profit) AS total_net_profit,
        1 AS level
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk

    UNION ALL

    SELECT 
        sh.ss_store_sk,
        sh.ss_item_sk, 
        sh.total_sales_quantity + s.total_sales_quantity,
        sh.total_net_profit + s.total_net_profit,
        sh.level + 1
    FROM sales_hierarchy sh
    JOIN store_sales s ON s.ss_store_sk = sh.ss_store_sk AND s.ss_item_sk = sh.ss_item_sk
    WHERE sh.level < 5
),

top_stores AS (
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        SUM(sh.total_sales_quantity) AS store_sales_quantity,
        SUM(sh.total_net_profit) AS store_net_profit
    FROM store s
    LEFT JOIN sales_hierarchy sh ON s.s_store_sk = sh.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
    ORDER BY store_net_profit DESC
    LIMIT 10
),

customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
)

SELECT
    ts.s_store_name,
    ts.store_sales_quantity,
    ts.store_net_profit,
    cs.total_orders,
    cs.total_sales,
    (CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales > 10000 THEN 'High Value'
        ELSE 'Normal Value'
    END) AS customer_value_category
FROM top_stores ts
LEFT JOIN customer_sales cs ON cs.c_customer_sk = (SELECT MAX(c.c_customer_sk) FROM customer c)
WHERE ts.store_sales_quantity > (SELECT AVG(store_sales_quantity) FROM top_stores)
ORDER BY ts.store_net_profit DESC;
