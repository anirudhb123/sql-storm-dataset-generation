
WITH customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        cs.income_band_sk
    FROM
        customer_stats cs
    WHERE
        cs.rank_by_purchase <= 10
),
sales_summary AS (
    SELECT
        coalesce(ws_bill_customer_sk, ss_customer_sk) AS customer_sk,
        SUM(ws_net_paid) AS total_sales_web,
        SUM(ss_net_paid) AS total_sales_store,
        COUNT(DISTINCT coalesce(ws_order_number, ss_ticket_number)) AS total_orders
    FROM
        web_sales ws
    FULL OUTER JOIN
        store_sales ss ON ws.ws_bill_customer_sk = ss.ss_customer_sk
    GROUP BY
        coalesce(ws_bill_customer_sk, ss_customer_sk)
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    ss.total_sales_web,
    ss.total_sales_store,
    ss.total_orders,
    (CASE
        WHEN ss.total_sales_web IS NULL AND ss.total_sales_store IS NULL THEN 'No Sales'
        WHEN ss.total_sales_web IS NOT NULL AND ss.total_sales_store IS NULL THEN 'Online Only'
        WHEN ss.total_sales_web IS NULL AND ss.total_sales_store IS NOT NULL THEN 'In-Store Only'
        ELSE 'Both Channels'
    END) AS sales_channel,
    (SELECT STRING_AGG(sm.sm_type, ', ') 
     FROM ship_mode sm
     WHERE sm.sm_ship_mode_sk IN (SELECT ws_ship_mode_sk FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_sk)) AS preferred_shipping_modes
FROM
    top_customers tc
LEFT JOIN
    sales_summary ss ON tc.c_customer_sk = ss.customer_sk
WHERE
    tc.income_band_sk IS NOT NULL OR tc.income_band_sk = -1
ORDER BY
    total_sales_web DESC NULLS LAST,
    total_sales_store DESC NULLS LAST,
    tc.c_last_name
LIMIT 50;
