
WITH RECURSIVE sales_cte AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450020 AND 2450180
), 
demographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_buy_potential
),
returns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk > 2450120
    GROUP BY sr_item_sk
)
SELECT
    s.ws_item_sk,
    SUM(s.ws_quantity) AS total_quantity,
    SUM(s.ws_net_profit) AS total_profit,
    d.customer_count,
    COALESCE(r.total_returns, 0) AS total_returns
FROM sales_cte s
LEFT JOIN demographics d ON s.ws_item_sk = d.c_customer_sk
LEFT JOIN returns r ON s.ws_item_sk = r.sr_item_sk
GROUP BY s.ws_item_sk, d.customer_count
HAVING SUM(s.ws_quantity) > 100
ORDER BY total_profit DESC
LIMIT 10;
