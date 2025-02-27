
WITH CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_income
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
TopCustomers AS (
    SELECT *
    FROM CustomerStatistics
    WHERE rank_income <= 10
),
IncomeBandStats AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS num_customers,
        AVG(total_spent) AS avg_spent,
        MAX(total_spent) AS max_spent,
        MIN(total_spent) AS min_spent
    FROM TopCustomers tc
    JOIN household_demographics hd ON tc.cd_income_band_sk = hd.hd_income_band_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    is.null_if(num_customers, 0) AS num_customers,
    coalesce(avg_spent, 0) AS avg_spent,
    coalesce(max_spent, 0) AS max_spent,
    coalesce(min_spent, 0) AS min_spent
FROM income_band ib
LEFT JOIN IncomeBandStats ibs ON ib.ib_income_band_sk = ibs.ib_income_band_sk
ORDER BY ib.ib_income_band_sk;
