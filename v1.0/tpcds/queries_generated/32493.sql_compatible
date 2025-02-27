
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 
           CAST(c_first_name AS VARCHAR(100)) AS path, 
           0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 
           CONCAT(ch.path, ' -> ', c.c_first_name) AS path, 
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.level < 5
),
sales_summary AS (
    SELECT 
        w.w_warehouse_id, 
        COUNT(ws.ws_order_number) AS total_orders, 
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
      AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY w.w_warehouse_id
    HAVING SUM(ws.ws_sales_price) > 10000
),
customer_purchase AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_paid) IS NOT NULL AND COUNT(ws.ws_order_number) > 0
),
final_report AS (
    SELECT 
        ch.path,
        cs.total_orders,
        cs.total_sales,
        cs.avg_sales_price,
        cp.total_spent,
        cp.order_count
    FROM sales_summary cs
    FULL OUTER JOIN customer_purchase cp ON cs.total_orders IS NULL OR cp.order_count IS NOT NULL
    JOIN customer_hierarchy ch ON cp.rank = 1
)

SELECT 
    fr.path,
    COALESCE(fr.total_orders, 0) AS total_orders,
    COALESCE(fr.total_sales, 0) AS total_sales,
    ROUND(COALESCE(fr.avg_sales_price, 0), 2) AS avg_sales_price,
    ROUND(COALESCE(fr.total_spent, 0), 2) AS total_spent,
    COALESCE(fr.order_count, 0) AS order_count
FROM final_report fr
WHERE fr.total_sales > 50000
ORDER BY fr.total_sales DESC
LIMIT 100;
