
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
item_prior_month AS (
    SELECT 
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_qty
    FROM item i
    JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY i.i_item_id
),
customer_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.buy_potential,
    total_qty,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
    AVG(rs.ws_sales_price) AS avg_sales_price,
    MAX(CASE WHEN rs.price_rank = 1 THEN rs.ws_sales_price END) AS max_sales_price,
    SUM(CASE WHEN rs.ws_quantity > 0 THEN rs.ws_sales_price ELSE 0 END) AS total_positive_sales
FROM customer_info ci
LEFT JOIN item_prior_month ipm ON ci.c_customer_id = ipm.i_item_id
LEFT JOIN ranked_sales rs ON ci.c_customer_id = rs.ws_order_number
GROUP BY ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.buy_potential, total_qty
ORDER BY total_sales DESC, ci.c_customer_id;
