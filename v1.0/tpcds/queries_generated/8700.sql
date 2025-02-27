
WITH CustomerPerformance AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ss.ss_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns_value
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
IncomeAnalysis AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT cp.c_customer_id) AS customer_count,
        AVG(cp.total_spent) AS avg_spent,
        SUM(cp.total_orders) AS total_orders
    FROM CustomerPerformance cp
    JOIN household_demographics hd ON cp.hd_income_band_sk = hd.hd_income_band_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ia.customer_count,
    ia.avg_spent,
    ia.total_orders,
    RANK() OVER (ORDER BY ia.avg_spent DESC) AS spending_rank
FROM IncomeAnalysis ia
JOIN income_band ib ON ia.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY spending_rank;
