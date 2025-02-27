
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        s_store_sk,
        s_store_name,
        1 AS level,
        ss_item_sk,
        ss_quantity,
        ss_ext_sales_price
    FROM
        store_sales ss
    JOIN store s ON ss_store_sk = s_store_sk
    WHERE
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    UNION ALL
    SELECT
        s_store_sk,
        s_store_name,
        level + 1,
        ss_item_sk,
        ss_quantity,
        ss_ext_sales_price
    FROM
        store_sales ss
    JOIN store s ON ss_store_sk = s_store_sk
    JOIN SalesHierarchy sh ON ss_item_sk = sh.ss_item_sk
    WHERE
        ss_quantity > 0
        AND sh.level < 5
)
SELECT
    s.s_store_name,
    SUM(sh.ss_quantity) AS total_quantity,
    AVG(sh.ss_ext_sales_price) AS avg_sales_price,
    MIN(sh.ss_ext_sales_price) AS min_sales_price,
    MAX(sh.ss_ext_sales_price) AS max_sales_price,
    COUNT(DISTINCT sh.s_store_sk) AS store_count
FROM
    SalesHierarchy sh
JOIN store s ON sh.s_store_sk = s.s_store_sk
WHERE
    sh.ss_quantity IS NOT NULL
GROUP BY
    s.s_store_name
HAVING
    SUM(sh.ss_quantity) > 0
ORDER BY
    total_quantity DESC
FETCH FIRST 10 ROWS ONLY;

WITH TotalReturns AS (
    SELECT
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM
        store_returns sr
    GROUP BY
        sr_store_sk
)
SELECT
    s.s_store_name,
    COALESCE(r.total_returned, 0) AS total_returned
FROM
    store s
LEFT JOIN TotalReturns r ON s.s_store_sk = r.s_store_sk
WHERE
    s.s_closed_date_sk IS NULL
ORDER BY
    total_returned DESC;
