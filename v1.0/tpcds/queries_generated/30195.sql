
WITH RECURSIVE item_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        is.total_quantity,
        is.total_profit
    FROM item i
    JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
    WHERE is.rank <= 10
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM web_sales
    JOIN customer c ON ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
customer_demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate > 1000
)
SELECT
    ci.i_item_id,
    ci.i_item_desc,
    cs.c_customer_sk,
    cs.order_count,
    cs.total_spent,
    cd.cd_gender,
    cd.cd_marital_status
FROM top_items ci
FULL OUTER JOIN customer_sales cs ON cs.total_spent > ci.total_profit
LEFT JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE cs.order_count > 0 OR cd.cd_demo_sk IS NULL
ORDER BY ci.total_profit DESC, cs.total_spent DESC;
