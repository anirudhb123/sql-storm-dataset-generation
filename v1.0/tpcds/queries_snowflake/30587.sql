
WITH IncomeBandTree AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 0 AS level
    FROM income_band
    WHERE ib_lower_bound = (SELECT MIN(ib_lower_bound) FROM income_band)

    UNION ALL

    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, it.level + 1
    FROM income_band ib
    JOIN IncomeBandTree it ON ib.ib_lower_bound BETWEEN it.ib_lower_bound AND it.ib_upper_bound
    WHERE it.level < 5
),
SalesData AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2021)
    GROUP BY c.c_customer_sk
),
BandyCust AS (
    SELECT 
        s.c_customer_sk,
        CASE 
            WHEN (s.total_sales IS NULL OR s.total_sales = 0) THEN NULL
            ELSE it.ib_income_band_sk
        END AS income_band_sk
    FROM SalesData s
    LEFT JOIN IncomeBandTree it ON s.total_sales BETWEEN it.ib_lower_bound AND it.ib_upper_bound
)
SELECT 
    bc.income_band_sk,
    COUNT(DISTINCT bc.c_customer_sk) AS customer_count,
    SUM(sd.total_sales) AS total_sales,
    AVG(sd.order_count) AS avg_order_count
FROM BandyCust bc
LEFT JOIN SalesData sd ON bc.c_customer_sk = sd.c_customer_sk
GROUP BY bc.income_band_sk
ORDER BY customer_count DESC NULLS LAST;
