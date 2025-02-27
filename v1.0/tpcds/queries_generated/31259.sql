
WITH RECURSIVE sales_summary AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM
        web_sales ws
    GROUP BY
        ws.web_site_sk, ws.ws_sold_date_sk
), top_sales AS (
    SELECT
        web_site_sk,
        total_quantity,
        total_profit
    FROM
        sales_summary
    WHERE
        rn <= 5
), customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), detailed_report AS (
    SELECT
        cs.web_site_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.buy_potential,
        cs.total_quantity,
        cs.total_profit,
        ROW_NUMBER() OVER (PARTITION BY ci.buy_potential ORDER BY cs.total_profit DESC) AS rank
    FROM
        top_sales cs
    JOIN customer_info ci ON cs.web_site_sk = (SELECT ws.web_site_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = ci.c_customer_sk LIMIT 1)
)
SELECT
    dr.buy_potential,
    COUNT(dr.c_first_name) AS number_of_customers,
    AVG(dr.total_profit) AS avg_profit
FROM
    detailed_report dr
WHERE
    dr.rank <= 3
GROUP BY
    dr.buy_potential
ORDER BY
    number_of_customers DESC
