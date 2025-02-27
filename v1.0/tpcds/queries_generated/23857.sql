
WITH RECURSIVE AddressTree AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 0 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL 

    UNION ALL

    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, at.level + 1
    FROM customer_address a
    JOIN AddressTree at ON a.ca_state = at.ca_state AND a.ca_city = at.ca_city
    WHERE at.level < 5
),
CustomerStats AS (
    SELECT c.c_customer_sk,
           CASE 
               WHEN cd.cd_gender = 'M' THEN 'Male'
               WHEN cd.cd_gender = 'F' THEN 'Female'
               ELSE 'Unknown'
           END AS gender,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_profit) AS total_profit,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
IncomeProjection AS (
    SELECT h.hd_income_band_sk,
           COUNT(hd_demo_sk) AS household_count,
           AVG(h.hd_vehicle_count) AS avg_vehicles,
           MAX(h.hd_buy_potential) AS best_buy_potential
    FROM household_demographics h
    GROUP BY h.hd_income_band_sk
    HAVING COUNT(hd_demo_sk) > 10
),
SalesPerformance AS (
    SELECT ss.s_store_sk,
           SUM(ss.ss_net_profit) AS store_profit,
           SUM(ss.ss_quantity) AS total_units_sold,
           RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS rank
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_closed_date_sk IS NULL
    GROUP BY ss.s_store_sk
)
SELECT 
    CASE
        WHEN cs.total_profit IS NOT NULL THEN cs.total_profit
        ELSE 0 
    END AS total_profit,
    COALESCE(s.store_profit, 0) AS store_profit,
    at.ca_city,
    at.ca_state,
    at.ca_country,
    ip.household_count
FROM AddressTree at
LEFT JOIN CustomerStats cs ON cs.c_customer_sk IN (SELECT DISTINCT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = at.ca_city))
LEFT JOIN SalesPerformance s ON s.s_store_sk = (SELECT s_store_sk FROM store WHERE s.state = at.ca_state ORDER BY s.s_store_sk LIMIT 1)
LEFT JOIN IncomeProjection ip ON ip.hd_income_band_sk = cs.avg_purchase_estimate
WHERE at.level = (SELECT MAX(level) FROM AddressTree)

ORDER BY total_profit DESC, store_profit DESC
LIMIT 100;
