
WITH RECURSIVE IncomeBands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk = 1
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN IncomeBands ib_prev ON ib.ib_income_band_sk = ib_prev.ib_income_band_sk + 1
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        COALESCE(sr_return_amt, 0) AS total_return_amt,
        COALESCE(sr_return_tax, 0) AS total_return_tax,
        COUNT(*) OVER (PARTITION BY sr_item_sk) AS return_count,
        sr_customer_sk
    FROM store_returns
    WHERE sr_returned_date_sk > 20230101
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    ia.ib_income_band_sk,
    COALESCE(cd.cd_gender, 'N/A') AS gender,
    SUM(sd.total_sales_price) AS total_sales,
    SUM(cr.total_return_amt) AS total_returns,
    SUM(cr.total_return_tax) AS total_return_tax,
    SUM(sd.total_net_profit) AS total_net_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM CustomerReturns cr
JOIN SalesData sd ON cr.sr_item_sk = sd.ws_item_sk
JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN IncomeBands ia ON cd.cd_purchase_estimate BETWEEN ia.ib_lower_bound AND ia.ib_upper_bound
GROUP BY ia.ib_income_band_sk, cd.cd_gender
HAVING SUM(sd.total_sales_price) > 1000
ORDER BY ia.ib_income_band_sk, gender;
