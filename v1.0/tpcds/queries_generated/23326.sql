
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_profit) > 1000
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(CASE WHEN cd.cd_purchase_estimate IS NOT NULL THEN cd.cd_purchase_estimate ELSE 0 END) AS max_purchase_estimate,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
high_orders AS (
    SELECT 
        cs.cs_ship_mode_sk,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    INNER JOIN total_sales ts ON cs.cs_item_sk = ts.ws_item_sk
    GROUP BY cs.cs_ship_mode_sk
    HAVING SUM(cs.cs_net_paid) IS NOT NULL
),
final_result AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        hs.total_net_paid,
        heading.*
    FROM customer_stats cs
    LEFT JOIN high_orders hs ON cs.order_count > 5
    JOIN (SELECT DISTINCT r.r_reason_desc 
          FROM reason r 
          WHERE r.r_reason_sk IN (SELECT cr_reason_sk FROM catalog_returns)
          ORDER BY r.r_reason_desc) heading ON TRUE
    LEFT JOIN ranked_sales rs ON cs.order_count IS NOT NULL
)

SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.total_profit,
    fr.total_net_paid,
    COALESCE(fr.profit_rank, 'No Profit Rank') AS profit_rank_position,
    IFNULL(fr.total_net_paid, 0) AS adjusted_net_paid
FROM final_result fr
WHERE fr.total_profit IS NOT NULL OR fr.total_net_paid IS NULL
ORDER BY fr.total_net_paid DESC, fr.c_last_name ASC
LIMIT 100 OFFSET 50;
