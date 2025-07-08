
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count,
           c.c_current_addr_sk, c.c_birth_year, 0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count,
           c.c_current_addr_sk, c.c_birth_year, ch.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_addr_sk
    WHERE cd.cd_marital_status = 'S' AND ch.level < 2
),
OrderDetail AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ws.ws_bill_customer_sk
),
RelevantShippingModes AS (
    SELECT DISTINCT sm.sm_ship_mode_id, sm.sm_type, sm.sm_carrier
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender, od.total_net_profit, 
       od.total_orders, rsm.sm_ship_mode_id, rsm.sm_type, rsm.sm_carrier
FROM CustomerHierarchy ch
LEFT JOIN OrderDetail od ON ch.c_customer_sk = od.ws_bill_customer_sk AND od.rank = 1
LEFT JOIN RelevantShippingModes rsm ON od.total_orders > 0
WHERE ch.c_birth_year BETWEEN 1970 AND 1990
      AND (od.total_net_profit IS NOT NULL OR rsm.sm_ship_mode_id IS NULL)
ORDER BY ch.c_last_name ASC, ch.c_first_name ASC;
