
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
best_customers AS (
    SELECT 
        rc.c_customer_sk,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_net_profit
    FROM ranked_customers rc
    WHERE rc.gender_rank <= 5
)
SELECT 
    bc.full_name,
    bc.cd_gender,
    bc.cd_marital_status,
    COALESCE(bc.total_net_profit, 0) AS total_net_profit,
    COALESCE(sm.sm_type, 'Standard') AS shipping_mode,
    COUNT(cr.cr_item_sk) AS returned_items_count
FROM best_customers bc
LEFT JOIN catalog_returns cr ON bc.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = 
    (SELECT ws.ws_ship_mode_sk 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = bc.c_customer_sk 
     ORDER BY ws.ws_net_profit DESC 
     LIMIT 1)
GROUP BY bc.full_name, bc.cd_gender, bc.cd_marital_status, bc.total_net_profit, sm.sm_type
ORDER BY total_net_profit DESC
LIMIT 10;
