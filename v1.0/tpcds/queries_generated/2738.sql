
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.net_paid > 0
    GROUP BY ws.web_site_sk, ws_sold_date_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(COALESCE(ws.ws_net_profit, 0)) AS avg_net_profit,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        RANK() OVER (ORDER BY COUNT(ws.ws_order_number) DESC) AS item_rank
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING COUNT(ws.ws_order_number) > 50
)
SELECT
    ws.web_site_sk,
    r.total_sales_quantity,
    r.total_net_profit,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.avg_net_profit, 0) AS avg_net_profit,
    pi.i_item_id,
    pi.order_count,
    pi.total_quantity_sold
FROM ranked_sales r
LEFT JOIN customer_summary cs ON r.web_site_sk = cs.c_customer_sk
INNER JOIN popular_items pi ON r.total_sales_quantity = pi.total_quantity_sold
WHERE r.sales_rank <= 5
ORDER BY r.web_site_sk, r.total_sales_quantity DESC;
