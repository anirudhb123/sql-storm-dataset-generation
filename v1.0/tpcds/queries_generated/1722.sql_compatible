
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS rnk
    FROM web_sales ws
    INNER JOIN customer c ON ws.bill_customer_sk = c.customer_sk
    LEFT JOIN customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    LEFT JOIN call_center cc ON c.current_addr_sk = cc.call_center_sk
    WHERE ws.sold_date_sk = (SELECT MAX(ws1.sold_date_sk) FROM web_sales ws1)
    GROUP BY ws.web_site_id
),
top_web_sites AS (
    SELECT web_site_id, total_net_profit, total_orders
    FROM ranked_sales
    WHERE rnk <= 5
),
customer_stats AS (
    SELECT 
        c.customer_id, 
        cd.gender, 
        cd.marital_status, 
        COUNT(ws.order_number) AS order_count,
        SUM(ws.net_profit) AS total_profit,
        AVG(ws.net_paid_inc_tax) AS avg_order_value
    FROM customer c
    JOIN web_sales ws ON c.customer_sk = ws.bill_customer_sk
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    WHERE ws.sold_date_sk IN (SELECT MAX(sold_date_sk) FROM web_sales)
    GROUP BY c.customer_id, cd.gender, cd.marital_status
)
SELECT 
    tws.web_site_id, 
    tws.total_net_profit,
    tws.total_orders,
    cs.customer_id,
    cs.gender,
    cs.marital_status,
    cs.order_count,
    cs.total_profit,
    cs.avg_order_value,
    CASE 
        WHEN cs.order_count IS NULL THEN 'No orders'
        ELSE 'Has orders'
    END AS order_status
FROM top_web_sites tws
LEFT JOIN customer_stats cs ON tws.total_net_profit = cs.total_profit
ORDER BY tws.total_net_profit DESC, cs.order_count DESC;
