
WITH RECURSIVE sales_rank AS (
    SELECT
        ws.sold_date_sk,
        ws.item_sk,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.sold_date_sk ORDER BY ws.net_profit DESC) AS rank
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        cd.cd_gender
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_sales AS (
    SELECT
        sr.item_sk,
        SUM(sr.return_quantity) AS total_returns
    FROM store_returns sr
    INNER JOIN sales_rank sr_rank ON sr.item_sk = sr_rank.item_sk
    WHERE sr_rank.rank <= 5
    GROUP BY sr.item_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(ws.ws_net_profit) AS total_profit,
    COALESCE(ts.total_returns, 0) AS total_returns,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM customer_info ci
JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN top_sales ts ON ws.ws_item_sk = ts.item_sk
WHERE ci.cd_income_band_sk IS NOT NULL 
AND (ci.cd_marital_status = 'M' OR ci.cd_gender = 'F')
GROUP BY ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
HAVING total_profit > 1000
ORDER BY total_profit DESC;
