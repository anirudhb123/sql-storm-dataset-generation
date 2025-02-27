
WITH recent_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, cd_gender, cd_marital_status, cd_income_band_sk
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE c_first_shipto_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS average_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_ext_sales_price) > 1000
),
customer_summary AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.total_spent,
        ss.order_count,
        ss.average_profit
    FROM recent_customers rc
    LEFT JOIN sales_summary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN household_demographics hd ON rc.cd_income_band_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COUNT(DISTINCT w.ws_order_number) AS total_orders,
    SUM(w.ws_net_profit) AS total_profit,
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Purchases'
        WHEN c.total_spent < 500 THEN 'Low Spender'
        WHEN c.total_spent >= 500 AND c.total_spent < 1500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM customer_summary c
LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
GROUP BY c.c_first_name, c.c_last_name, c.total_spent
ORDER BY total_profit DESC
LIMIT 100;
