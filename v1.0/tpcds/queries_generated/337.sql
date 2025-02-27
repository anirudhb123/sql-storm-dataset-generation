
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_quantity ELSE 0 END) AS total_catalog_quantity,
        SUM(CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS total_web_quantity,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns
    FROM customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    JOIN (SELECT d_year, d_date_sk FROM date_dim WHERE d_year BETWEEN 2020 AND 2022) d ON d.d_date_sk = COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk, sr.sr_returned_date_sk, cr.cr_returned_date_sk)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
IncomeBandStats AS (
    SELECT 
        hd.hd_income_band_sk, 
        SUM(cs.cs_quantity + ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM household_demographics hd 
    LEFT JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY hd.hd_income_band_sk
),
FinalReport AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.d_year,
        COALESCE(cs.total_catalog_quantity, 0) AS catalog_sales,
        COALESCE(cs.total_web_quantity, 0) AS web_sales,
        cs.total_store_returns,
        cs.total_catalog_returns,
        ib.total_quantity_sold AS income_band_sales,
        ib.customer_count AS income_band_customer_count
    FROM CustomerStats cs 
    LEFT JOIN IncomeBandStats ib ON ib.hd_income_band_sk = (SELECT hd.hd_income_band_sk FROM household_demographics hd WHERE hd.hd_demo_sk = cs.c_customer_sk) 
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.d_year,
    f.catalog_sales,
    f.web_sales,
    f.total_store_returns,
    f.total_catalog_returns,
    f.income_band_sales,
    f.income_band_customer_count
FROM FinalReport f
ORDER BY f.d_year, f.c_last_name, f.c_first_name;
