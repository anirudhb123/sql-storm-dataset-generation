
WITH RECURSIVE sales_summary AS (
    SELECT
        s_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(*) AS total_transactions
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY
        s_store_sk
    
    UNION ALL

    SELECT
        ss.s_store_sk,
        SUM(ss.ss_sales_price) + COALESCE(SUM(ss2.ss_sales_price), 0) AS total_sales,
        SUM(1) + COALESCE(SUM(ss2.total_transactions), 0) AS total_transactions
    FROM
        store_sales ss
        LEFT JOIN sales_summary ss2 ON ss.s_store_sk = ss2.s_store_sk
    GROUP BY
        ss.s_store_sk
),
item_returns AS (
    SELECT
        ir.cr_item_sk,
        SUM(ir.cr_return_quantity) AS total_returns
    FROM
        catalog_returns ir
    WHERE
        ir.cr_returned_date_sk IS NOT NULL
    GROUP BY
        ir.cr_item_sk
),
filtered_customers AS (
    SELECT
        c.c_customer_sk,
        CASE
            WHEN d.d_year = 2022 THEN '2022_Customer'
            ELSE 'Other'
        END AS sales_year
    FROM
        customer c
        JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
)
SELECT
    ss.s_store_sk,
    ss.total_sales,
    ss.total_transactions,
    COALESCE(ir.total_returns, 0) AS total_returned_items,
    fc.sales_year
FROM
    sales_summary ss
LEFT JOIN item_returns ir ON ss.s_store_sk = ir.cr_item_sk
RIGHT JOIN filtered_customers fc ON ss.s_store_sk = fc.c_customer_sk
WHERE
    ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary) 
    AND fc.sales_year = '2022_Customer'
ORDER BY
    ss.total_sales DESC;
