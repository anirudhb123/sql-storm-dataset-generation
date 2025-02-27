
WITH RegionalSales AS (
    SELECT
        s.s_store_sk,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT CASE WHEN c.c_customer_sk IS NOT NULL THEN c.c_customer_sk END) AS unique_customers,
        DENSE_RANK() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM
        store s
    LEFT JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY
        s.s_store_sk, s.s_state
),
TopStores AS (
    SELECT
        rs.s_store_sk,
        rs.total_sales,
        rs.unique_customers
    FROM
        RegionalSales rs
    WHERE
        rs.sales_rank <= 5
),
CustomerReturns AS (
    SELECT
        cs.cs_item_sk,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM
        catalog_sales cs
    LEFT JOIN
        store_returns sr ON cs.cs_item_sk = sr.sr_item_sk
    GROUP BY
        cs.cs_item_sk
),
SalesWithReturns AS (
    SELECT
        ts.total_sales,
        ts.unique_customers,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (ts.total_sales - COALESCE(cr.total_returns, 0)) AS net_sales
    FROM
        TopStores ts
    LEFT JOIN
        CustomerReturns cr ON ts.total_sales = cr.total_returns
)
SELECT
    s.s_store_sk,
    s.total_sales,
    s.unique_customers,
    s.net_sales,
    CASE 
        WHEN s.net_sales > 100000 THEN 'High Value'
        WHEN s.net_sales BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category,
    CONCAT('Store ID: ', s.s_store_sk, ', Sales: $', ROUND(s.total_sales, 2)) AS sales_summary
FROM
    SalesWithReturns s
WHERE
    s.unique_customers > 10
ORDER BY
    s.total_sales DESC
LIMIT 10;
