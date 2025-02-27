
WITH RECURSIVE SalesSummary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
ShipModes AS (
    SELECT
        sm_ship_mode_id,
        sm_carrier,
        COUNT(ws.order_number) AS order_count
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm_ship_mode_id, sm_carrier
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.total_quantity) AS total_quantity,
    SUM(ss.total_net_paid) AS total_net_paid,
    cd.ca_city,
    cd.ca_state,
    sm.sm_carrier,
    CASE 
        WHEN SUM(ss.total_net_paid) > 1000 THEN 'High Roller'
        WHEN SUM(ss.total_net_paid) BETWEEN 500 AND 1000 THEN 'Moderate Buyer'
        ELSE 'Budget Shopper'
    END AS shopper_category,
    CASE 
        WHEN COUNT(ss.ws_order_number) > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS purchase_frequency
FROM CustomerDetails cd
JOIN SalesSummary ss ON cd.c_customer_sk = ss.ws_customer_sk
LEFT JOIN ShipModes sm ON ss.ws_item_sk = sm.ws_item_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cd.ca_city, 
    cd.ca_state, 
    sm.sm_carrier
HAVING SUM(ss.total_quantity) > 0
ORDER BY total_net_paid DESC
LIMIT 10;
