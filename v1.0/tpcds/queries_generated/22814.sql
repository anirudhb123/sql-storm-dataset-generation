
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
DemographicStats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_spent,
        ROW_NUMBER() OVER (PARTITION BY cs.total_sales ORDER BY cs.total_spent DESC) as rank
    FROM CustomerStats cs
    WHERE cs.total_spent IS NOT NULL
),
IncomeStats AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS income_customer_count
    FROM household_demographics h
    JOIN customer c ON c.c_current_hdemo_sk = h.hd_demo_sk
    GROUP BY h.hd_income_band_sk
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ic.income_customer_count,
    tc.total_sales,
    tc.total_spent
FROM DemographicStats ds
JOIN IncomeStats ic ON ds.customer_count > ic.income_customer_count
FULL OUTER JOIN TopCustomers tc ON ds.customer_count < tc.total_sales
WHERE (ds.cd_gender = 'F' AND ds.cd_marital_status IS NOT NULL)
   OR (ds.cd_gender = 'M' AND ds.avg_purchase_estimate > 1000)
ORDER BY 
    COALESCE(ds.customer_count, 0) DESC,
    COALESCE(tc.total_spent, 0) DESC
LIMIT 100;
