
WITH sales_summary AS (
    SELECT
        ws.ws_web_page_sk,
        DATE(d.d_date) AS sale_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws.ws_web_page_sk, d.d_date
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_age_group,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rn
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    s.ws_web_page_sk,
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_income_band_sk,
    ss.total_quantity,
    ss.total_profit
FROM
    sales_summary ss
LEFT JOIN
    web_page s ON ss.ws_web_page_sk = s.wp_web_page_sk
JOIN
    customer_info cs ON ss.total_orders > 5 AND cs.rn <= 10
WHERE
    s.wp_creation_date_sk IS NOT NULL 
    AND (ss.total_profit IS NOT NULL OR ss.total_quantity > 0)
ORDER BY
    ss.total_profit DESC
LIMIT 100;
