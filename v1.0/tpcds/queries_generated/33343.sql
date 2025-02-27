
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_ship_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_ship_date_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_purchase_estimate,
        (SELECT MAX(hd_vehicle_count) 
         FROM household_demographics 
         WHERE hd_demo_sk = c.c_current_hdemo_sk) AS max_vehicles,
        (SELECT COUNT(*) 
         FROM store_sales 
         WHERE ss_customer_sk = c.c_customer_sk) AS total_store_purchases
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    ci.cd_purchase_estimate,
    ci.max_vehicles,
    ss.total_net_profit AS highest_profit,
    COALESCE(ss.total_net_profit / NULLIF(ci.total_store_purchases, 0), 0) AS avg_profit_per_purchase
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_id = (
    SELECT ws_bill_customer_sk 
    FROM web_sales 
    WHERE ws_ship_date_sk = (
        SELECT MAX(ws_ship_date_sk) FROM web_sales
    )
)
WHERE ci.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
AND ci.gender IS NOT NULL
ORDER BY highest_profit DESC
LIMIT 100;
