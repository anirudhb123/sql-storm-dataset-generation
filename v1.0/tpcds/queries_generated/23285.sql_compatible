
WITH RECURSIVE address_tree AS (
    SELECT ca_address_id, ca_city, ca_state,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT NULL, ca_city, ca_state,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) + city_rank
    FROM customer_address
    WHERE ca_state IS NOT NULL AND city_rank < 10
    AND EXISTS (SELECT 1 FROM address_tree a WHERE a.ca_city = customer_address.ca_city)
),
customer_summary AS (
    SELECT c.c_customer_id, 
           COUNT(DISTINCT w.ws_order_number) AS total_orders,
           SUM(w.ws_net_profit) AS total_profit,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id
),
warehouse_sales AS (
    SELECT w.w_warehouse_id,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
           SUM(ws.ws_net_paid_inc_ship_tax) AS total_revenue_with_shipping
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
),
item_sales AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS total_store_quantity,
           SUM(ss.ss_net_paid) AS total_store_revenue,
           SUM(ws.ws_quantity) AS total_web_quantity,
           SUM(ws.ws_net_paid) AS total_web_revenue
    FROM item i
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
)
SELECT a.ca_city, 
       a.ca_state,
       cs.c_customer_id,
       cs.total_orders,
       cs.total_profit,
       ws.total_quantity,
       ws.total_revenue,
       ws.total_revenue_with_shipping,
       it.total_store_quantity,
       it.total_store_revenue,
       it.total_web_quantity,
       it.total_web_revenue
FROM address_tree a
JOIN customer_summary cs ON cs.c_customer_id IS NOT NULL
FULL OUTER JOIN warehouse_sales ws ON ws.total_quantity IS NOT NULL
FULL OUTER JOIN item_sales it ON it.total_store_quantity IS NOT NULL
WHERE (cs.total_profit > 1000 OR cs.total_orders > 5)
AND a.city_rank IS NOT NULL
AND (EXISTS (SELECT 1 FROM warehouse_sales w WHERE w.total_revenue > 5000)
OR NOT EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = it.i_item_id))
ORDER BY a.ca_state, a.ca_city, cs.total_profit DESC;
