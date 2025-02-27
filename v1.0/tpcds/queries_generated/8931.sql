
WITH Customer_Purchase_Summary AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_transaction_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
Aggregate_Summary AS (
    SELECT
        hd.hd_income_band_sk,
        COUNT(DISTINCT cps.c_customer_id) AS num_customers,
        AVG(cps.total_spent) AS avg_spent,
        SUM(cps.store_transaction_count) AS total_store_transactions,
        SUM(cps.web_transaction_count) AS total_web_transactions
    FROM Customer_Purchase_Summary cps
    JOIN household_demographics hd ON cps.hd_income_band_sk = hd.hd_income_band_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(as.num_customers, 0) AS num_customers,
    COALESCE(as.avg_spent, 0) AS avg_spent,
    COALESCE(as.total_store_transactions, 0) AS total_store_transactions,
    COALESCE(as.total_web_transactions, 0) AS total_web_transactions
FROM income_band ib
LEFT JOIN Aggregate_Summary as ON ib.ib_income_band_sk = as.hd_income_band_sk
ORDER BY ib.ib_income_band_sk;
