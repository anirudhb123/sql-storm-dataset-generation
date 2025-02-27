
WITH RECURSIVE IncomeLevels AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk = 1
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    INNER JOIN IncomeLevels il ON ib.ib_income_band_sk = il.ib_income_band_sk + 1
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS income_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
),
HighSpenders AS (
    SELECT * 
    FROM CustomerSummary
    WHERE total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
),
TempResults AS (
    SELECT 
        h.c_customer_sk,
        h.c_first_name,
        h.c_last_name,
        h.total_spent,
        CASE 
            WHEN h.total_spent BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound THEN ib.ib_income_band_sk
            ELSE NULL
        END AS income_band
    FROM HighSpenders h
    LEFT JOIN IncomeLevels ib ON h.total_spent BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    COALESCE(t.income_band, 'Unknown') AS income_band,
    COUNT(DISTINCT s.ss_ticket_number) AS store_purchases,
    SUM(s.ss_net_profit) AS total_store_profit,
    MAX(ws.ws_net_profit) AS max_web_profit
FROM TempResults t
LEFT JOIN store_sales s ON t.c_customer_sk = s.ss_customer_sk
LEFT JOIN web_sales ws ON t.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY t.c_customer_sk, t.c_first_name, t.c_last_name, t.total_spent, t.income_band
ORDER BY total_spent DESC, store_purchases DESC;
