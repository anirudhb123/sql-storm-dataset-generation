
WITH customer_details AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        hd.hd_income_band_sk, 
        hd.hd_buy_potential 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_items_sold
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ws_bill_customer_sk
),
final_report AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ss.total_net_profit,
        ss.total_orders,
        ss.total_items_sold
    FROM customer_details cd 
    LEFT JOIN sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    customer_id, 
    first_name, 
    last_name, 
    gender, 
    marital_status, 
    education_status, 
    purchase_estimate, 
    income_band_sk, 
    buy_potential, 
    total_net_profit, 
    total_orders, 
    total_items_sold 
FROM final_report 
WHERE total_net_profit > 1000 
ORDER BY total_net_profit DESC 
LIMIT 100;
