
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns_count,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_returns_count
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY c.c_customer_id
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
GenderIncome AS (
    SELECT 
        cd.cd_gender,
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY cd.cd_gender, ib.ib_income_band_sk
)
SELECT 
    cr.c_customer_id,
    COALESCE(cr.web_returns_count, 0) AS web_returns,
    COALESCE(cr.catalog_returns_count, 0) AS catalog_returns,
    ss.total_web_sales,
    ss.web_order_count,
    gi.cd_gender,
    gi.ib_income_band_sk,
    gi.customer_count
FROM CustomerReturns cr
FULL OUTER JOIN SalesSummary ss ON cr.c_customer_id = ss.ws_bill_customer_sk
FULL OUTER JOIN GenderIncome gi ON gi.customer_count > 0
WHERE (ss.total_web_sales IS NOT NULL OR cr.web_returns_count IS NOT NULL)
  AND (gi.customer_count IS NULL OR gi.customer_count > 10)
ORDER BY cr.c_customer_id, gi.cd_gender, gi.ib_income_band_sk;
