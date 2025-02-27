
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date, d_year, 1 AS level
    FROM date_dim
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim)
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, ds.level + 1
    FROM date_dim d
    JOIN date_series ds ON d.d_date_sk = ds.d_date_sk - 1
    WHERE ds.level < 365
),
sales_summary AS (
    SELECT 
        COALESCE(wp.wp_web_page_id, 'Unknown') AS web_page_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_sales_price) / NULLIF(COUNT(ws.ws_order_number), 0) AS avg_sales_per_order,
        ROW_NUMBER() OVER (PARTITION BY wp.wp_web_page_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_series)
    GROUP BY wp.wp_web_page_id
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) FILTER (WHERE ws.ws_sales_price > 100) AS high_value_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.max_purchase_estimate, 0) AS max_purchase_estimate,
    ss.web_page_id,
    ss.total_orders AS web_orders,
    ss.total_sales AS web_sales,
    ss.avg_sales_price,
    ss.avg_sales_per_order
FROM customer_info cs
FULL OUTER JOIN sales_summary ss ON ss.total_orders > 5
WHERE cs.total_spent > 1000
ORDER BY cs.total_spent DESC, ss.total_sales DESC
LIMIT 100;
