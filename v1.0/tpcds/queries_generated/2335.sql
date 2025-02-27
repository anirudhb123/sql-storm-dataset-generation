
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM
        web_sales
),
customer_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        cd.cd_marital_status = 'M'
        AND hd.hd_income_band_sk IS NOT NULL
),
sales_summary AS (
    SELECT
        r.ws_item_sk,
        SUM(r.ws_quantity) AS total_quantity,
        SUM(r.ws_sales_price) AS total_sales,
        COUNT(DISTINCT r.ws_bill_customer_sk) AS unique_customers
    FROM
        web_sales r
    JOIN
        customer_info ci ON ci.c_customer_id = r.ws_bill_customer_sk
    GROUP BY
        r.ws_item_sk
)
SELECT
    si.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    CASE
        WHEN ss.unique_customers > 100 THEN 'High'
        WHEN ss.unique_customers BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_engagement_level
FROM
    sales_summary ss
JOIN
    item si ON ss.ws_item_sk = si.i_item_sk
JOIN
    customer_info ci ON si.i_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE price_rank = 1)
WHERE
    ss.total_sales > 1000
ORDER BY
    ss.total_sales DESC
LIMIT 10;
