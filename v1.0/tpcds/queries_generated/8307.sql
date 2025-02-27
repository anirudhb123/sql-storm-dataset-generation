
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
store_data AS (
    SELECT 
        ss.ss_sold_date_sk, 
        ss.ss_item_sk, 
        SUM(ss.ss_quantity) AS total_quantity, 
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
),
combined_sales AS (
    SELECT 
        sd.ws_sold_date_sk AS sold_date_sk,
        sd.ws_item_sk AS item_sk,
        COALESCE(sd.total_quantity, 0) + COALESCE(st.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_net_profit, 0) + COALESCE(st.total_net_profit, 0) AS total_net_profit
    FROM sales_data sd
    FULL OUTER JOIN store_data st ON sd.ws_sold_date_sk = st.ss_sold_date_sk AND sd.ws_item_sk = st.ss_item_sk
)
SELECT 
    ci.c_customer_sk, 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(cs.total_quantity) AS overall_quantity,
    SUM(cs.total_net_profit) AS overall_net_profit
FROM customer_info ci
JOIN combined_sales cs ON ci.c_customer_sk = cs.ws_bill_customer_sk
GROUP BY 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status
ORDER BY overall_net_profit DESC
LIMIT 10;
