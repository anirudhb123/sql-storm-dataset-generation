
WITH RECURSIVE DateCTE AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_year >= 2015
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq
    FROM date_dim d
    JOIN DateCTE dc ON d.d_date_sk = dc.d_date_sk + 1
),
CustomerDetails AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           SUM(COALESCE(ss.net_profit, 0)) AS total_store_profit,
           SUM(COALESCE(ws.net_profit, 0)) AS total_web_profit,
           COUNT(DISTINCT CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_ticket_number END) AS store_purchases,
           COUNT(DISTINCT CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_order_number END) AS web_purchases
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
IncomeAnalysis AS (
    SELECT h.hd_income_band_sk,
           SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
           SUM(CASE WHEN cd.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
    FROM household_demographics h
    JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY h.hd_income_band_sk
)
SELECT cd.c_first_name,
       cd.c_last_name,
       cd.cd_gender,
       total_store_profit,
       total_web_profit,
       married_count,
       single_count,
       EXTRACT(MONTH FROM d.d_date) AS sales_month
FROM CustomerDetails cd
JOIN IncomeAnalysis ia ON cd.c_customer_sk = ia.hd_demo_sk
JOIN DateCTE d ON d.d_year = 2022
WHERE (total_store_profit + total_web_profit) > 0
ORDER BY total_store_profit DESC, total_web_profit DESC;
