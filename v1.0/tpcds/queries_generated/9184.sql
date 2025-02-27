
WITH CustomerData AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_web_page_sk) AS unique_pages_viewed
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY
        ws_bill_customer_sk
),
JoinedData AS (
    SELECT
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        sd.total_sales,
        sd.total_orders,
        sd.total_discount,
        sd.unique_pages_viewed,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        CustomerData cd
    LEFT JOIN
        SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.ib_lower_bound,
    c.ib_upper_bound,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_orders, 0) AS total_orders,
    (COALESCE(s.total_sales, 0) / NULLIF(COALESCE(s.total_orders, 0), 0)) AS avg_order_value,
    COUNT(wp.wp_web_page_sk) AS pages_viewed_count
FROM
    JoinedData c
LEFT JOIN
    web_page wp ON c.c_customer_id = wp.wp_customer_sk
WHERE
    c.cd_marital_status = 'M' AND
    c.total_sales > 1000
GROUP BY
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.ib_lower_bound,
    c.ib_upper_bound,
    s.total_sales,
    s.total_orders
ORDER BY
    total_sales DESC
LIMIT 100;
