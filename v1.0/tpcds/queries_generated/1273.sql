
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales AS ws
    JOIN warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY ws.web_site_sk, w.w_warehouse_name
),
TopSales AS (
    SELECT 
        web_site_sk,
        w_warehouse_name,
        total_sales
    FROM RankedSales
    WHERE sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
CustomerReturnsFiltered AS (
    SELECT 
        cr.sr_returning_customer_sk,
        cr.total_return_amt,
        cd.cd_gender,
        cd.cd_marital_status
    FROM CustomerReturns AS cr
    LEFT JOIN customer_demographics AS cd ON cr.sr_returning_customer_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
),
AggregatedReturns AS (
    SELECT 
        COUNT(*) AS total_female_returns,
        SUM(total_return_amt) AS total_female_return_amount
    FROM CustomerReturnsFiltered
)
SELECT 
    ts.web_site_sk,
    ts.w_warehouse_name,
    ts.total_sales,
    ar.total_female_returns,
    ar.total_female_return_amount,
    CASE 
        WHEN ar.total_female_returns IS NULL THEN 0 
        ELSE ar.total_female_return_amount / NULLIF(ar.total_female_returns, 0) 
    END AS average_return_amount_per_female
FROM TopSales AS ts
LEFT JOIN AggregatedReturns AS ar ON ts.web_site_sk = ar.sr_returning_customer_sk
ORDER BY ts.total_sales DESC, ts.w_warehouse_name;
