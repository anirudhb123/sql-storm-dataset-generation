
WITH RECURSIVE Address_Hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 0 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, ah.level + 1
    FROM customer_address a
    JOIN Address_Hierarchy ah ON a.ca_state = ah.ca_state
    WHERE a.ca_city <> ah.ca_city AND a.ca_country = ah.ca_country
),
Filtered_Customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_gender, 
           d.cd_marital_status, ROW_NUMBER() OVER(PARTITION BY d.cd_gender ORDER BY d.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE d.cd_purchase_estimate > 1000 AND (d.cd_gender = 'M' OR d.cd_gender IS NULL)
),
Sales_Summary AS (
    SELECT ws.ws_item_sk, COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(CASE WHEN ws.ws_ship_date_sk IS NULL THEN 1 ELSE 0 END) AS null_ship_dates
    FROM web_sales ws
    LEFT JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    GROUP BY ws.ws_item_sk
),
Final_Join AS (
    SELECT c.c_first_name, c.c_last_name, ah.ca_city, ah.ca_state, s.total_orders, 
           s.total_profit, s.null_ship_dates
    FROM Filtered_Customers c
    LEFT JOIN Address_Hierarchy ah ON c.c_customer_sk = ah.ca_address_sk
    LEFT JOIN Sales_Summary s ON 1 = (CASE 
                                           WHEN s.total_orders IS NULL THEN 0 
                                           ELSE 1 
                                       END)
    ORDER BY s.total_profit DESC NULLS LAST
)
SELECT *
FROM Final_Join
WHERE EXISTS (
    SELECT 1
    FROM warehouse w
    WHERE w.w_warehouse_sk IN (SELECT inv.w_inv_warehouse_sk
                                FROM inventory inv 
                                WHERE inv.inv_quantity_on_hand < 5)
    AND w.w_state = Final_Join.ca_state
)
OR NOT EXISTS (
    SELECT 1
    FROM ship_mode sm
    WHERE sm.sm_type LIKE '%Express%'
    AND sm.sm_ship_mode_sk IN (SELECT ws.ws_ship_mode_sk FROM web_sales ws)
);
