
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(sum(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(sum(ws.ws_quantity), 0) AS total_web_sales
    FROM
        item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_sk, i.i_item_id
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    s.total_sales,
    i.total_catalog_sales,
    i.total_web_sales
FROM
    customer_info ci
LEFT JOIN ranked_sales s ON s.ws_item_sk IN (
    SELECT ws_item_sk
    FROM ranked_sales
    WHERE sales_rank <= 10 AND total_sales > 1000
)
LEFT JOIN item_sales i ON i.i_item_sk = s.ws_item_sk
WHERE
    (ci.dependent_count = 0 AND ci.vehicle_count > 1) OR
    (ci.dependent_count > 2 AND ci.cd_gender IS NOT NULL)
ORDER BY
    total_sales DESC,
    ci.c_last_name ASC
LIMIT 100;
