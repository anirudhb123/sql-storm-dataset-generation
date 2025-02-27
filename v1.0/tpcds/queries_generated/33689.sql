
WITH RECURSIVE CTE_TotalSales AS (
    SELECT ws.web_site_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.web_site_sk
),
CTE_CustomerInfo AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT CAST(c_c.customer_sk AS VARCHAR)) AS number_of_orders,
           COALESCE(cd.cd_gender, 'Unknown') AS gender,
           COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
CTE_NetProfit AS (
    SELECT ss.ss_store_sk,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ss.ss_store_sk
)
SELECT w.w_warehouse_name,
       SUM(s.total_net_profit) AS total_store_net_profit,
       SUM(t.total_sales) AS total_web_sales,
       COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
       COUNT(DISTINCT ci.income_band) AS different_income_bands,
       'Total Performance Metrics' AS performance_metric
FROM warehouse w
LEFT JOIN CTE_NetProfit s ON w.w_warehouse_sk = s.ss_store_sk
LEFT JOIN CTE_TotalSales t ON w.w_warehouse_sk = t.web_site_sk
LEFT JOIN CTE_CustomerInfo ci ON ci.number_of_orders > 10
GROUP BY w.w_warehouse_name
HAVING SUM(s.total_net_profit) IS NOT NULL
ORDER BY total_store_net_profit DESC;
