
WITH CustomerStats AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(CASE WHEN ws_sold_date_sk IS NOT NULL THEN ws_quantity ELSE 0 END) AS total_web_purchases,
        SUM(CASE WHEN ss_sold_date_sk IS NOT NULL THEN ss_quantity ELSE 0 END) AS total_store_purchases,
        SUM(CASE WHEN cs_sold_date_sk IS NOT NULL THEN cs_quantity ELSE 0 END) AS total_catalog_purchases
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
PurchaseSummary AS (
    SELECT
        d.d_year,
        SUM(total_web_purchases) AS total_web_sales,
        SUM(total_store_purchases) AS total_store_sales,
        SUM(total_catalog_purchases) AS total_catalog_sales
    FROM
        CustomerStats cs
    JOIN
        date_dim d ON d.d_date_sk IN (
            SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_bill_customer_sk = cs.c_customer_id
            UNION
            SELECT DISTINCT ss_sold_date_sk FROM store_sales WHERE ss_customer_sk = cs.c_customer_id
            UNION
            SELECT DISTINCT cs_sold_date_sk FROM catalog_sales WHERE cs_bill_customer_sk = cs.c_customer_id
        )
    GROUP BY
        d.d_year
)
SELECT
    ps.d_year,
    ps.total_web_sales,
    ps.total_store_sales,
    ps.total_catalog_sales,
    (ps.total_web_sales + ps.total_store_sales + ps.total_catalog_sales) AS total_sales,
    (ps.total_web_sales * 100.0 / NULLIF(ps.total_web_sales + ps.total_store_sales + ps.total_catalog_sales, 0)) AS web_sales_percentage,
    (ps.total_store_sales * 100.0 / NULLIF(ps.total_web_sales + ps.total_store_sales + ps.total_catalog_sales, 0)) AS store_sales_percentage,
    (ps.total_catalog_sales * 100.0 / NULLIF(ps.total_web_sales + ps.total_store_sales + ps.total_catalog_sales, 0)) AS catalog_sales_percentage
FROM
    PurchaseSummary ps
ORDER BY
    ps.d_year DESC;
