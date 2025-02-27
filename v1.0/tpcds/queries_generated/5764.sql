
WITH CustomerReturns AS (
    SELECT 
        CASE 
            WHEN wr_returning_customer_sk IS NOT NULL THEN wr_returning_customer_sk 
            ELSE cr_returning_customer_sk 
        END AS customer_sk,
        COALESCE(SUM(wr_return_amt), 0) AS total_web_return_amt,
        COALESCE(SUM(cr_return_amount), 0) AS total_catalog_return_amt
    FROM web_returns wr
    FULL OUTER JOIN catalog_returns cr ON wr_returning_customer_sk = cr_returning_customer_sk
    GROUP BY customer_sk
),
StoreSales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2459534 AND 2459539 -- Date range for analysis
    GROUP BY ss_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COALESCE(CR.total_web_return_amt, 0) AS total_web_return_amt,
        COALESCE(CR.total_catalog_return_amt, 0) AS total_catalog_return_amt,
        COALESCE(SS.total_sales, 0) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns CR ON c.c_customer_sk = CR.customer_sk
    LEFT JOIN StoreSales SS ON c.c_customer_sk = SS.ss_customer_sk
    WHERE COALESCE(SS.total_sales, 0) > 1000 -- Minimum sales threshold
    AND (COALESCE(CR.total_web_return_amt, 0) + COALESCE(CR.total_catalog_return_amt, 0)) < 200 -- Return limits
)
SELECT 
    hvc.c_customer_sk, 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.cd_gender, 
    hvc.cd_marital_status, 
    hvc.cd_income_band_sk, 
    hvc.total_sales,
    hvc.total_web_return_amt,
    hvc.total_catalog_return_amt
FROM HighValueCustomers hvc
ORDER BY hvc.total_sales DESC
LIMIT 100; -- Return top 100 high value customers
