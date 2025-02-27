
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM
        web_sales ws
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        w.web_country = 'USA' AND
        ws.ws_sold_date_sk BETWEEN 1500 AND 2000
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE
        cd.cd_credit_rating IS NOT NULL
)
SELECT
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_income_band_sk,
    COUNT(rs.ws_order_number) AS total_orders,
    SUM(rs.ws_sales_price) AS total_revenue,
    MAX(rs.ws_net_profit) AS max_net_profit
FROM
    customer_info ci
LEFT JOIN
    ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk
WHERE
    (ci.cd_income_band_sk IS NULL OR ci.cd_income_band_sk > 5)
GROUP BY
    ci.c_customer_sk, ci.cd_gender, ci.cd_income_band_sk
HAVING
    COUNT(rs.ws_order_number) > 1
ORDER BY
    total_revenue DESC
LIMIT 100;

SELECT
    'Equal' AS comparison,
    COUNT(*) AS count
FROM
    web_returns wr
WHERE
    wr.wr_return_amt = ANY (SELECT DISTINCT ws.ws_net_paid FROM web_sales ws)
UNION ALL
SELECT
    'Not Equal',
    COUNT(*)
FROM
    web_returns wr
WHERE
    wr.wr_return_amt <> ALL (SELECT DISTINCT ws.ws_net_paid FROM web_sales ws);
