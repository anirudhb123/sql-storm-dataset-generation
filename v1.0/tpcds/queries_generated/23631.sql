
WITH RECURSIVE sales_rank AS (
    SELECT
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk IS NOT NULL
),
item_stats AS (
    SELECT
        i_item_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    JOIN item ON ws_item_sk = i_item_sk
    GROUP BY i_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd_marital_status,
        cd_gender,
        COUNT(DISTINCT ws_order_number) AS orders,
        COUNT(DISTINCT ws_item_sk) AS items_purchased,
        SUM(ws_net_profit) AS total_spent
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, cd_marital_status, cd_gender
)
SELECT
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.orders,
    ci.items_purchased,
    ci.total_spent,
    ISNULL(ir.total_income_band, 'Unknown') AS income_band,
    COALESCE(RANK() OVER (ORDER BY ci.total_spent DESC), 'Unranked') AS customer_rank,
    CASE 
        WHEN ci.total_spent >= 5000 THEN 'High Value'
        WHEN ci.total_spent >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM customer_info ci
LEFT JOIN (
    SELECT
        hd_demo_sk,
        MAX(ib_income_band_sk) AS total_income_band
    FROM household_demographics
    LEFT JOIN income_band ON hd_income_band_sk = ib_income_band_sk
    WHERE ib_lower_bound IS NOT NULL
    GROUP BY hd_demo_sk
) ir ON ci.c_current_cdemo_sk = ir.hd_demo_sk
WHERE ci.total_spent > (
    SELECT AVG(total_spent) FROM customer_info
)
AND ci.orders > (
    SELECT COUNT(DISTINCT ws_order_number) / COUNT(DISTINCT c_customer_sk)
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
ORDER BY ci.total_spent DESC
LIMIT 50;
