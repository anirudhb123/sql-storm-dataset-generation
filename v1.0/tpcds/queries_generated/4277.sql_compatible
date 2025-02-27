
WITH SalesStats AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_net_profit) AS avg_profit
    FROM store_sales
    GROUP BY s_store_sk
),
TopStores AS (
    SELECT 
        s_store_sk,
        total_sales,
        total_transactions,
        avg_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesStats
),
GenderIncome AS (
    SELECT 
        cd_gender,
        ib_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd_gender IS NOT NULL
    GROUP BY cd_gender, ib_income_band_sk
),
SalesGender AS (
    SELECT 
        ss.s_store_sk,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_sales_by_gender
    FROM store_sales AS ss
    JOIN customer AS c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ss.s_store_sk, cd.cd_gender
),
FinalReport AS (
    SELECT 
        ts.s_store_sk,
        ts.total_sales,
        ts.total_transactions,
        ts.avg_profit,
        COALESCE(SUM(sg.total_sales_by_gender), 0) AS total_sales_by_gender,
        COALESCE(SUM(gi.customer_count), 0) AS total_customers_income
    FROM TopStores AS ts
    LEFT JOIN SalesGender AS sg ON ts.s_store_sk = sg.s_store_sk
    LEFT JOIN GenderIncome AS gi ON sg.cd_gender = gi.cd_gender
    GROUP BY ts.s_store_sk, ts.total_sales, ts.total_transactions, ts.avg_profit
)
SELECT 
    fr.s_store_sk,
    fr.total_sales,
    fr.total_transactions,
    fr.avg_profit,
    fr.total_sales_by_gender,
    fr.total_customers_income
FROM FinalReport AS fr
WHERE fr.total_sales > (SELECT AVG(total_sales) FROM FinalReport)
  AND fr.total_transactions > 10
ORDER BY fr.total_sales DESC;
