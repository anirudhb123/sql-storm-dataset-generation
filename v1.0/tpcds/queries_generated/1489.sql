
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(COALESCE(COALESCE(ss.ss_net_profit, 0), 0) + COALESCE(cs.cs_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
IncomeDistribution AS (
    SELECT
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate
    FROM household_demographics hd
    LEFT JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_net_profit DESC) AS rn
    FROM CustomerStats cs
    WHERE cs.total_net_profit > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    id.customer_count,
    id.total_vehicles,
    id.avg_purchase_estimate,
    CASE 
        WHEN tc.total_net_profit IS NULL THEN 'No Purchases'
        WHEN tc.total_net_profit < 1000 THEN 'Low Value'
        ELSE 'High Value'
    END AS customer_value_category
FROM TopCustomers tc
JOIN IncomeDistribution id ON tc.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk IN (SELECT hd.hd_demo_sk FROM household_demographics hd WHERE hd.hd_income_band_sk = id.hd_income_band_sk))
WHERE tc.rn <= 10;
