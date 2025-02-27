
WITH sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00
    GROUP BY ws.ws_item_sk
),
top_sales AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_net_profit,
        ss.total_orders,
        ss.profit_rank,
        i.i_product_name,
        i.i_brand
    FROM sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE ss.profit_rank <= 10
),
customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ts.total_quantity_sold,
    ts.total_net_profit,
    ts.total_orders,
    i.i_category,
    ts.i_brand
FROM top_sales ts
JOIN customer_info ci ON ts.ws_item_sk IN (
    SELECT DISTINCT ws.ws_item_sk 
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = ci.c_customer_sk
)
LEFT JOIN item i ON ts.ws_item_sk = i.i_item_sk
WHERE ci.income_band > 0
ORDER BY ts.total_net_profit DESC, ci.c_last_name ASC
LIMIT 50;
