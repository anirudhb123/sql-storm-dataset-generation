
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_ext_sales_price > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
),
SalesSummary AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_count,
        SUM(CASE WHEN ws.ws_ext_sales_price IS NULL THEN 1 ELSE 0 END) AS null_sales_count
    FROM
        web_sales ws
    LEFT JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year IS NOT NULL
        AND (
            (c.c_birth_month IS NULL AND c.c_birth_day BETWEEN 1 AND 31)
            OR (c.c_birth_day IS NULL AND c.c_birth_month IN (1, 3, 5, 7))
            OR (c.c_birth_day IS NOT NULL AND c.c_birth_month IS NOT NULL)
        )
    GROUP BY
        ws.web_site_sk
),
StoreReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, sr_return_quantity, sr_reason_sk
    HAVING 
        SUM(sr_return_amt) > (SELECT AVG(sr_return_amt) FROM store_returns)
)
SELECT 
    ss.web_site_sk,
    ss.total_sales,
    ss.sales_count,
    rs.sales_rank,
    COALESCE(sr.total_return_amt, 0) AS total_return_amount
FROM 
    SalesSummary ss
LEFT JOIN 
    RankedSales rs ON ss.web_site_sk = rs.web_site_sk
LEFT JOIN 
    StoreReturns sr ON rs.ws_order_number = sr.sr_item_sk
WHERE 
    ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
