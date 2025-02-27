
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
RecentSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit
    FROM SalesData sd
    WHERE sd.rn <= 5
    GROUP BY sd.ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE cd.cd_income_band_sk IS NOT NULL 
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk
),
ProfitAnalysis AS (
    SELECT 
        ci.cd_income_band_sk,
        SUM(rs.total_profit) AS income_band_profit,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count
    FROM RecentSales rs
    JOIN CustomerInfo ci ON rs.ws_item_sk = ci.c_customer_sk
    GROUP BY ci.cd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(pa.income_band_profit, 0) AS total_profit,
    COALESCE(pa.customer_count, 0) AS total_customers,
    (COALESCE(pa.income_band_profit, 0) / NULLIF(COALESCE(pa.customer_count, 0), 0)) AS average_profit_per_customer
FROM income_band ib
LEFT JOIN ProfitAnalysis pa ON ib.ib_income_band_sk = pa.cd_income_band_sk
WHERE (ib.ib_lower_bound <= 50000 OR ib.ib_upper_bound IS NULL)
  AND (ib.ib_upper_bound >= 30000 OR ib.ib_lower_bound IS NULL)
ORDER BY ib.ib_income_band_sk;
