
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
SalesWithReturns AS (
    SELECT
        ws_b.bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COALESCE(CR.total_return_amt, 0) AS total_returns,
        CASE 
            WHEN SUM(ws_ext_sales_price) > 0 THEN (SUM(ws_ext_sales_price) - COALESCE(CR.total_return_amt, 0)) / SUM(ws_ext_sales_price)
            ELSE NULL 
        END AS net_sales_ratio
    FROM
        web_sales ws_b
    LEFT JOIN
        CustomerReturns CR ON ws_b.bill_customer_sk = CR.sr_customer_sk
    GROUP BY
        ws_b.bill_customer_sk
),
RankedSales AS (
    SELECT
        swr.bill_customer_sk,
        total_sales,
        total_discount,
        total_returns,
        net_sales_ratio,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesWithReturns swr
)
SELECT
    c.c_customer_id,
    cs.total_sales,
    cs.total_discount,
    cs.total_returns,
    cs.net_sales_ratio,
    CASE
        WHEN cs.net_sales_ratio IS NOT NULL AND cs.net_sales_ratio < 0.5 THEN 'Low Net Sales'
        WHEN cs.net_sales_ratio IS NOT NULL AND cs.net_sales_ratio >= 0.5 THEN 'High Net Sales'
        ELSE 'No Sales Data'
    END AS sales_category,
    R.sales_rank
FROM
    RankedSales R
JOIN
    customer c ON R.bill_customer_sk = c.c_customer_sk
WHERE
    c.c_birth_year < 1980
ORDER BY
    R.sales_rank
LIMIT 100;
