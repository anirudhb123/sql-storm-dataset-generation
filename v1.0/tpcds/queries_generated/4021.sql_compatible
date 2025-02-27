
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2451545 AND 2451550  
    GROUP BY
        ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dep_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT
        ci.c_customer_sk,
        SUM(ss.total_sales) AS total_sales
    FROM
        customer_info ci
    JOIN
        (
            SELECT
                ss_customer_sk,
                SUM(ss_ext_sales_price) AS total_sales
            FROM
                store_sales
            WHERE
                ss_sold_date_sk BETWEEN 2451545 AND 2451550
            GROUP BY
                ss_customer_sk
        ) ss ON ci.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        ci.c_customer_sk
    HAVING
        SUM(ss.total_sales) > 5000
),
top_item_sales AS (
    SELECT
        ws_item_sk AS s_item_sk,
        total_quantity,
        total_sales,
        total_discount
    FROM
        sales_summary
    WHERE
        rank <= 5
)
SELECT
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    hi.total_sales AS customer_total_sales,
    ti.total_quantity AS top_item_quantity,
    ti.total_sales AS top_item_sales,
    ti.total_discount AS top_item_discount
FROM
    high_value_customers hi
JOIN
    customer_info ci ON ci.c_customer_sk = hi.c_customer_sk
LEFT JOIN
    top_item_sales ti ON ti.s_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk)
ORDER BY
    hi.total_sales DESC,
    ti.total_sales DESC;
