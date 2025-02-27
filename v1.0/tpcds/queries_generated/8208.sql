
WITH customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS average_purchase_estimate,
        AVG(cd_credit_rating) AS average_credit_rating
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
sales_performance AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_ship_mode_sk
),
shipment_modes AS (
    SELECT 
        sm_ship_mode_sk,
        sm_carrier,
        sm_code
    FROM ship_mode
)
SELECT 
    cs.cd_gender,
    sp.ws_ship_mode_sk,
    sm.sm_carrier,
    ss.total_quantity_sold,
    ss.total_net_profit,
    cs.total_dependents,
    cs.average_purchase_estimate,
    cs.average_credit_rating
FROM customer_stats cs
JOIN sales_performance ss ON cs.customer_count > 100
JOIN shipment_modes sm ON ss.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY cs.cd_gender, ss.total_net_profit DESC;
