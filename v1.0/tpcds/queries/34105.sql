
WITH RECURSIVE SalesCTE AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk

    UNION ALL

    SELECT
        sc.ss_store_sk,
        sc.ss_sold_date_sk,
        SUM(sc.ss_quantity) AS total_quantity,
        SUM(sc.ss_net_paid) AS total_sales
    FROM store_sales sc
    JOIN SalesCTE cte ON sc.ss_store_sk = cte.ss_store_sk
    WHERE sc.ss_sold_date_sk < cte.ss_sold_date_sk
    GROUP BY sc.ss_store_sk, sc.ss_sold_date_sk
),
TotalStoreSales AS (
    SELECT
        s.s_store_name,
        SUM(cte.total_quantity) AS total_quantity,
        SUM(cte.total_sales) AS total_sales
    FROM store s
    LEFT JOIN SalesCTE cte ON s.s_store_sk = cte.ss_store_sk
    GROUP BY s.s_store_name
),
CustomerStats AS (
    SELECT
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT
    ts.s_store_name,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(cs.customer_count, 0) AS customer_count,
    COALESCE(cs.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    CASE
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        WHEN ts.total_sales > 1000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM TotalStoreSales ts
FULL OUTER JOIN CustomerStats cs ON 1=1
ORDER BY ts.total_sales DESC NULLS LAST;
