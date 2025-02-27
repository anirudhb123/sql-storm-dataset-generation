
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'

    UNION ALL

    SELECT 
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        sh.level + 1
    FROM store_returns sr 
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_hierarchy sh ON sr.sr_refunded_customer_sk = sh.c_customer_sk
    WHERE sr.sr_return_quantity > 0
),
ordered_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_ext_sales_price, cs.cs_ext_sales_price, ss.ss_ext_sales_price, 0)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_ext_sales_price, cs.cs_ext_sales_price, ss.ss_ext_sales_price, 0)) DESC) AS sales_rank
    FROM customer c 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
final_report AS (
    SELECT 
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_gender,
        sh.cd_marital_status,
        sh.cd_credit_rating,
        os.total_sales,
        os.sales_rank,
        ROW_NUMBER() OVER (ORDER BY os.total_sales DESC) AS overall_rank
    FROM sales_hierarchy sh
    LEFT JOIN ordered_sales os ON sh.c_customer_sk = os.c_customer_sk
    WHERE sh.level = 1
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_credit_rating,
    COALESCE(fr.total_sales, 0) AS total_sales,
    fr.sales_rank,
    fr.overall_rank
FROM final_report fr
ORDER BY fr.overall_rank, fr.c_last_name;
