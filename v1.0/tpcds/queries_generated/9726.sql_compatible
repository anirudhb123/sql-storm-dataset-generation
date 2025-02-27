
WITH CustomerReturns AS (
    SELECT
        sr.store_sk,
        COUNT(DISTINCT sr.ticket_number) AS return_count,
        SUM(sr.return_amt) AS total_return_amt,
        SUM(sr.return_tax) AS total_return_tax
    FROM
        store_returns sr
    WHERE
        sr.returned_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_moy = 10
        )
    GROUP BY
        sr.store_sk
),
StoreSales AS (
    SELECT
        ss.store_sk,
        COUNT(ss.ticket_number) AS sales_count,
        SUM(ss.sales_price) AS total_sales_amt,
        SUM(ss.ext_tax) AS total_sales_tax
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_moy = 10
        )
    GROUP BY
        ss.store_sk
),
StorePerformance AS (
    SELECT 
        s.store_id,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(ss.sales_count, 0) AS sales_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ss.total_sales_amt, 0) AS total_sales_amt,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        COALESCE(ss.total_sales_tax, 0) AS total_sales_tax
    FROM 
        store s
    LEFT JOIN 
        CustomerReturns cr ON s.store_sk = cr.store_sk
    LEFT JOIN 
        StoreSales ss ON s.store_sk = ss.store_sk
)
SELECT 
    store_id, 
    sales_count, 
    total_sales_amt, 
    total_sales_tax, 
    return_count, 
    total_return_amt, 
    total_return_tax, 
    (CASE WHEN total_sales_amt > 0 THEN (total_return_amt / total_sales_amt) * 100 ELSE 0 END) AS return_rate_percentage
FROM 
    StorePerformance
ORDER BY 
    return_rate_percentage DESC;
