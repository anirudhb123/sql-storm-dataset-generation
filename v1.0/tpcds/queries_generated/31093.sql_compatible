
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(SUM(CASE WHEN ss.ss_sold_date_sk BETWEEN 2451176 AND 2451235 THEN ss.ss_net_profit ELSE 0 END), 0) AS total_sales,
        1 AS level
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_credit_rating

    UNION ALL

    SELECT
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_marital_status,
        sh.cd_credit_rating,
        COALESCE(SUM(cs.cs_net_profit), 0) + sh.total_sales AS total_sales,
        sh.level + 1
    FROM
        sales_hierarchy AS sh
    JOIN
        catalog_sales AS cs ON sh.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.cd_marital_status, sh.cd_credit_rating, sh.total_sales, sh.level
)

SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.cd_marital_status,
    sh.cd_credit_rating,
    sh.total_sales,
    CASE 
        WHEN sh.total_sales = 0 THEN 'No Sales'
        WHEN sh.total_sales BETWEEN 1 AND 1000 THEN 'Low Sales'
        WHEN sh.total_sales BETWEEN 1001 AND 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY sh.cd_credit_rating ORDER BY sh.total_sales DESC) AS rank
FROM
    sales_hierarchy AS sh
WHERE
    sh.level = 1
ORDER BY
    sh.total_sales DESC
LIMIT 100;
