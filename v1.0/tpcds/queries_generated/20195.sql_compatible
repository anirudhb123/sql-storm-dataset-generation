
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        COUNT(*) OVER (PARTITION BY ws.ws_item_sk) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk > 0
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE 
            WHEN SUM(ws.ws_net_profit) IS NULL THEN 'UNDEFINED'
            WHEN SUM(ws.ws_net_profit) = 0 THEN 'NO_PROFIT'
            ELSE 'HAS_PROFIT' 
        END AS profit_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_items AS (
    SELECT
        rs.ws_item_sk,
        COUNT(DISTINCT rs.ws_order_number) AS unique_orders,
        SUM(CASE WHEN rs.rank_profit = 1 THEN rs.ws_net_profit ELSE 0 END) AS max_profit
    FROM ranked_sales rs
    WHERE rs.rank_profit <= 5
    GROUP BY rs.ws_item_sk
),
summary_with_income AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_profit,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN cs.total_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound THEN 'WITHIN_BAND'
            WHEN cs.total_profit IS NULL THEN 'NO_BAND'
            ELSE 'OUT_OF_BAND' 
        END AS profit_band_status
    FROM customer_summary cs
    LEFT JOIN household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
final_report AS (
    SELECT 
        sw.c_customer_sk,
        sw.total_profit,
        CASE 
            WHEN sw.profit_status = 'NO_PROFIT' AND sw.profit_band_status = 'NO_BAND' THEN 'Neglect'
            ELSE 'Review' 
        END AS action_required,
        ti.unique_orders,
        ti.max_profit
    FROM summary_with_income sw
    LEFT JOIN top_items ti ON sw.c_customer_sk = ti.ws_item_sk
)
SELECT 
    fr.c_customer_sk,
    fr.total_profit,
    fr.action_required,
    COALESCE(fr.unique_orders, 0) AS total_unique_orders,
    COALESCE(fr.max_profit, 0.00) AS max_profit_amount
FROM final_report fr
WHERE fr.action_required = 'Review' OR fr.total_profit IS NOT NULL
ORDER BY fr.total_profit DESC, fr.c_customer_sk;
