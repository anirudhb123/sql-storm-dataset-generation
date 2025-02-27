
WITH sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451560
    GROUP BY
        ws.ws_item_sk
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate < 100 THEN 'LOW'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS purchase_band
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
most_popular_items AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales
    FROM
        sales_summary ss
    WHERE
        ss.sales_rank <= 10
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.purchase_band,
    mpi.total_quantity,
    mpi.total_sales
FROM
    most_popular_items mpi
JOIN
    customer_data ci ON ci.c_customer_sk IN (
        SELECT DISTINCT ws.ws_bill_customer_sk
        FROM web_sales ws
        WHERE ws.ws_item_sk = mpi.ws_item_sk
    )
LEFT JOIN
    date_dim dd ON dd.d_date_sk = ws_sold_date_sk
ORDER BY
    mpi.total_sales DESC,
    ci.c_last_name ASC;
