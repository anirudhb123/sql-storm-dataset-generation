
WITH RECURSIVE SalesCTE AS (
    SELECT
        s_store_sk,
        SUM(ss_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY
        s_store_sk
),
CustomerReturns AS (
    SELECT
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM
        store_returns
    GROUP BY
        sr_store_sk
)
SELECT
    s.s_store_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales,
    CASE
        WHEN COALESCE(s.total_sales, 0) = 0 THEN NULL
        ELSE ROUND((COALESCE(r.total_returns, 0) * 100.0 / COALESCE(s.total_sales, 0)), 2)
    END AS return_rate_percentage
FROM
    (
        SELECT
            ss.s_store_sk,
            ss_store_name,
            SUM(ss_net_paid) AS total_sales
        FROM
            store s
        LEFT JOIN
            store_sales ss ON s.s_store_sk = ss.ss_store_sk
        GROUP BY
            ss.s_store_sk, s.s_store_name
    ) s
FULL OUTER JOIN
    CustomerReturns r ON s.s_store_sk = r.sr_store_sk
ORDER BY
    net_sales DESC;

