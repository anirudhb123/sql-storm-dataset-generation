
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           hd.hd_income_band_sk, hd.hd_buy_potential,
           0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           hd.hd_income_band_sk, hd.hd_buy_potential,
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk -- Hypothetical relationship for recursion
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE ch.level < 5
),
SalesSummary AS (
    SELECT ws_ship_date_sk, 
           SUM(ws_net_paid) AS total_sales,
           AVG(ws_net_profit) AS average_profit
    FROM web_sales
    WHERE ws_ship_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY ws_ship_date_sk
)
SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_marital_status, 
       ch.hd_income_band_sk, ch.hd_buy_potential, 
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(ss.average_profit, 0) AS average_profit,
       RANK() OVER (PARTITION BY ch.hd_income_band_sk ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
FROM CustomerHierarchy ch
LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_ship_date_sk
ORDER BY ch.hd_income_band_sk, sales_rank;
