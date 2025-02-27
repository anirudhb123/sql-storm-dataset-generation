
WITH RECURSIVE address_tree AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, 0 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_street_name, a.ca_city, a.ca_state, level + 1
    FROM customer_address a
    JOIN address_tree at ON a.ca_county = at.ca_city
    WHERE at.level < 3
),
customer_metrics AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           SUM(ws.ws_net_paid_inc_tax) AS total_spent,
           COUNT(DISTINCT ws.ws_order_number) AS orders_count,
           AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
           ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank,
           ca.ca_city,
           ca.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year > 1980 AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, ca.ca_city, ca.ca_state
),
shipping_modes AS (
    SELECT sm.sm_ship_mode_id, 
           SUM(ws.ws_net_paid) AS total_ship_net_paid
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 DAY')
    GROUP BY sm.sm_ship_mode_id
)
SELECT 
    cm.c_customer_sk,
    cm.c_first_name,
    cm.c_last_name,
    cm.total_spent,
    cm.orders_count,
    cm.avg_order_value,
    sm.total_ship_net_paid,
    COALESCE(ROW_NUMBER() OVER(PARTITION BY cm.ca_state ORDER BY cm.total_spent DESC), 0) AS state_rank,
    CASE 
        WHEN cm.total_spent IS NULL THEN 'No Purchases'
        WHEN cm.total_spent > 1000 THEN 'High Spender'
        ELSE 'Regular Spender' 
    END AS customer_category,
    (SELECT COUNT(DISTINCT c.c_customer_id) FROM customer c WHERE c.c_birth_year < 1980) AS legacy_customers
FROM customer_metrics cm
LEFT JOIN shipping_modes sm ON cm.c_customer_sk = sm.sm_ship_mode_id
WHERE cm.rank <= 5
ORDER BY cm.total_spent DESC, cm.c_last_name;
