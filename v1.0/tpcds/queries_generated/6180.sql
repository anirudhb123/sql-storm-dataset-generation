
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_units_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        ws_item_sk,
        total_units_sold,
        total_sales,
        total_discount,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM sales_summary
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.total_units_sold,
    ti.total_sales,
    ti.total_discount,
    ti.total_profit
FROM top_items ti
JOIN customer_info ci ON ci.c_customer_sk IN (
    SELECT 
        ws_bill_customer_sk 
    FROM web_sales 
    WHERE ws_item_sk = ti.ws_item_sk
)
WHERE ti.profit_rank <= 10
ORDER BY ti.total_profit DESC;
