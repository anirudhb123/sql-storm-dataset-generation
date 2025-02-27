
WITH RECURSIVE IncomeBands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    INNER JOIN IncomeBands ib_recursive ON ib.ib_income_band_sk = ib_recursive.ib_income_band_sk
    WHERE ib.ib_lower_bound > ib_recursive.ib_lower_bound
), SalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
), HighValueSales AS (
    SELECT sd.c_customer_sk, sd.c_first_name, sd.c_last_name, sd.total_sales, sd.order_count
    FROM SalesData sd
    WHERE sd.total_sales > (SELECT AVG(total_sales) FROM SalesData)
), SalesSummary AS (
    SELECT 
        hvs.c_customer_sk,
        hvs.c_first_name,
        hvs.c_last_name,
        hvs.total_sales,
        hvs.order_count,
        ib.ib_income_band_sk,
        CASE 
            WHEN hvs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound THEN 'Within Band'
            ELSE 'Out of Band'
        END AS sales_band_status
    FROM HighValueSales hvs
    LEFT JOIN IncomeBands ib ON hvs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
)
SELECT 
    s.c_customer_sk, 
    s.c_first_name, 
    s.c_last_name,
    s.total_sales,
    s.order_count,
    s.ib_income_band_sk,
    s.sales_band_status,
    COUNT(DISTINCT r.r_reason_sk) AS reason_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_quantity ELSE 0 END) AS positive_return_qty
FROM SalesSummary s
LEFT JOIN store_returns sr ON s.c_customer_sk = sr.sr_customer_sk
LEFT JOIN catalog_returns cr ON s.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk OR cr.cr_reason_sk = r.r_reason_sk
GROUP BY s.c_customer_sk, s.c_first_name, s.c_last_name, s.total_sales, s.order_count, s.ib_income_band_sk, s.sales_band_status
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY s.total_sales DESC
LIMIT 100;
