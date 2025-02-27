
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY
        ws.web_site_sk, ws.order_number
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_dep_count) AS min_dep_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
    GROUP BY
        c.c_customer_sk, c.c_current_cdemo_sk
),
top_sites AS (
    SELECT
        web_site_sk,
        total_sales,
        total_discount
    FROM
        ranked_sales
    WHERE
        sales_rank = 1
)
SELECT
    w.w_warehouse_id,
    cs.c_customer_sk,
    cs.max_purchase_estimate,
    cs.min_dep_count,
    ts.total_sales,
    ts.total_discount,
    COALESCE(CASE WHEN ts.total_discount > 0 THEN 1 ELSE 0 END, 0) AS discount_exists
FROM
    warehouse w
LEFT JOIN
    customer_stats cs ON cs.c_current_cdemo_sk IS NOT NULL
JOIN
    top_sites ts ON ts.web_site_sk = w.w_warehouse_sk
WHERE
    (ts.total_sales > 1000 OR cs.max_purchase_estimate > 5000)
    AND w.w_country IS NOT NULL
ORDER BY
    ts.total_sales DESC,
    cs.min_dep_count ASC
LIMIT 50;
