
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_day, c_birth_month, c_birth_year, 1 AS level
    FROM customer
    WHERE c_birth_year IS NOT NULL
    UNION ALL
    SELECT cc.c_customer_sk, cc.c_first_name, cc.c_last_name, 
           (c.birth_day + 1) % 30 AS c_birth_day, 
           (c.birth_month + (c.birth_day + 1) / 30) % 12 AS c_birth_month,
           (c.birth_year + (c.birth_month + (c.birth_day + 1) / 12) / 12) AS c_birth_year,
           level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_customer_sk = cc.c_customer_sk
    WHERE level < 10
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN CustomerCTE cc ON ws.ws_bill_customer_sk = cc.c_customer_sk
    GROUP BY ws.web_site_id
),
ShipModeData AS (
    SELECT 
        sm.sm_ship_mode_id,
        AVG(ws.ws_ext_ship_cost) AS avg_ship_cost
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
),
ReturnStatistics AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ca.ca_city,
    cs.total_profit,
    cs.total_orders,
    ss.avg_ship_cost,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount
FROM CustomerCTE cc
JOIN SalesData cs ON cc.c_customer_sk = cs.web_site_id
LEFT JOIN ShipModeData ss ON cs.web_site_id = ss.sm_ship_mode_id
LEFT JOIN ReturnStatistics rs ON cs.total_orders = rs.total_returns
JOIN customer_address ca ON cc.c_current_addr_sk = ca.ca_address_sk
WHERE cc.c_birth_year BETWEEN 1980 AND 2000
AND cs.rank = 1
ORDER BY cs.total_profit DESC, ca.ca_city;
