
WITH promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
),
warehouse_inventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
),
customer_analysis AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_dep_count > 0
    GROUP BY cd.cd_gender
)
SELECT 
    ws.web_site_id,
    ws.web_name,
    COALESCE(ps.total_orders, 0) AS total_orders,
    COALESCE(ps.total_net_profit, 0) AS total_net_profit,
    COALESCE(ps.total_discount, 0) AS total_discount,
    COALESCE(wi.total_quantity, 0) AS warehouse_total_quantity,
    ca.cd_gender,
    ca.customer_count,
    ca.avg_purchase_estimate
FROM web_site ws
LEFT JOIN promotion_summary ps ON ws.web_site_sk = ps.p_promo_id
LEFT JOIN warehouse_inventory wi ON ws.web_site_sk = wi.inv_warehouse_sk
LEFT JOIN customer_analysis ca ON ws.web_site_sk = ca.cd_gender
WHERE (ps.total_net_profit IS NOT NULL OR wi.total_quantity IS NOT NULL)
  AND (ca.customer_count > 10 OR ca.avg_purchase_estimate > 1000)
ORDER BY ws.web_name, total_orders DESC;
