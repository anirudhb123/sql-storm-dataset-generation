
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
customer_demo AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_segment
    FROM
        customer_demographics cd
),
sales_summary AS (
    SELECT
        cs.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.purchase_segment,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS total_sales
    FROM
        customer_sales cs
    JOIN customer_demo cd ON cs.c_customer_id = cd.cd_demo_sk
)
SELECT
    purchase_segment,
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT c_customer_id) AS num_customers,
    SUM(total_sales) AS total_sales_value,
    AVG(total_sales) AS average_sales_value
FROM
    sales_summary
GROUP BY
    purchase_segment, cd_gender, cd_marital_status
ORDER BY
    purchase_segment, num_customers DESC, total_sales_value DESC;
