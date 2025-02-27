
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        DENSE_RANK() OVER (PARTITION BY c.current_cdemo_sk ORDER BY COALESCE(SUM(ws.ws_sales_price), 0) DESC) AS web_rank,
        DENSE_RANK() OVER (PARTITION BY c.current_cdemo_sk ORDER BY COALESCE(SUM(ss.ss_sales_price), 0) DESC) AS store_rank
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id, c.current_cdemo_sk
),
ReturnDetails AS (
    SELECT
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(cr.cr_order_number) AS total_returns
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_returning_customer_sk
),
SalesSummary AS (
    SELECT
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_store_sales,
        rd.total_return_amount,
        rd.total_returns
    FROM
        CustomerSales cs
    LEFT JOIN
        ReturnDetails rd ON cs.c_customer_id = rd.cr_returning_customer_sk
)
SELECT
    s.c_customer_id,
    CASE 
        WHEN s.total_store_sales > s.total_web_sales THEN 'Store'
        WHEN s.total_web_sales > s.total_store_sales THEN 'Web'
        ELSE 'Equal'
    END AS preferred_channel,
    ROW_NUMBER() OVER (ORDER BY s.total_web_sales DESC, s.total_store_sales DESC) AS ranking,
    COALESCE(NULLIF(s.total_return_amount, 0), 'No Returns') AS return_status,
    CASE 
        WHEN s.total_returns IS NULL THEN 'No Returns'
        WHEN s.total_returns > 5 THEN 'High Returns'
        WHEN s.total_returns BETWEEN 1 AND 5 THEN 'Moderate Returns'
        ELSE 'No Returns'
    END AS return_category
FROM
    SalesSummary s
WHERE
    
    (s.total_web_sales > 1000 OR s.total_store_sales > 1000)
    AND (s.total_return_amount IS NULL OR s.total_return_amount > 0)
    AND (s.total_web_sales != s.total_store_sales
         OR (s.total_store_sales IS NULL AND s.total_web_sales IS NOT NULL))
ORDER BY 
    preferred_channel, ranking
LIMIT 50;
