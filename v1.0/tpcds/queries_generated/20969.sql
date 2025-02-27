
WITH RECURSIVE IncomeDistribution AS (
    SELECT ib_income_band_sk,
           ib_lower_bound,
           ib_upper_bound,
           0 AS depth
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           id.depth + 1
    FROM income_band ib
    JOIN IncomeDistribution id ON id.ib_income_band_sk = ib.ib_income_band_sk
    WHERE id.depth < 5
),
CustomerReturns AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           COUNT(DISTINCT sr_ticket_number) AS total_returns,
           SUM(COALESCE(sr_return_amt, 0) + COALESCE(sr_return_tax, 0)) AS total_return_value
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE sr_return_quantity > 0
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
StorePerformance AS (
    SELECT s.s_store_id,
           SUM(ws_quantity) AS total_quantity_sold,
           SUM(ws_net_profit) AS total_net_profit
    FROM store s
    JOIN web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    GROUP BY s.s_store_id
),
DetailedCustomerReturns AS (
    SELECT cr.c_customer_id,
           cr.total_returns,
           cr.total_return_value,
           d.cdemo_sk,
           d.cd_gender,
           d.cd_marital_status,
           d.cd_education_status,
           d.cd_purchase_estimate
    FROM CustomerReturns cr
    JOIN customer_demographics d ON cr.c_customer_id = d.cd_demo_sk
    WHERE cr.total_returns > 5 AND d.cd_credit_rating IS NOT NULL
),
WarehouseStats AS (
    SELECT w.w_warehouse_id,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
    HAVING COUNT(DISTINCT ws.ws_order_number) > 10
)
SELECT id.ib_income_band_sk,
       id.ib_lower_bound,
       id.ib_upper_bound,
       SUM(dcr.total_returns) AS total_customer_returns,
       SUM(dcr.total_return_value) AS total_value_of_returns,
       sp.s_store_id,
       SUM(sp.total_quantity_sold) AS total_sold,
       SUM(sp.total_net_profit) AS total_profit,
       ws.total_orders AS total_warehouse_orders
FROM IncomeDistribution id
LEFT JOIN DetailedCustomerReturns dcr ON dcr.cdemo_sk = (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'F' LIMIT 1)
LEFT JOIN StorePerformance sp ON dcr.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = dcr.cdemo_sk)
LEFT JOIN WarehouseStats ws ON 1=1
GROUP BY id.ib_income_band_sk, id.ib_lower_bound, id.ib_upper_bound, sp.s_store_id, ws.total_orders
ORDER BY total_value_of_returns DESC, total_customer_returns DESC
LIMIT 100 OFFSET 0;
