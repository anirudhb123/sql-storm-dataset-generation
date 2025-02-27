
WITH RECURSIVE income_distribution AS (
    SELECT 
        hd_demo_sk,
        SUM(CASE 
            WHEN ib_upper_bound IS NOT NULL THEN ib_upper_bound 
            ELSE 0 
        END) AS upper_bound_total,
        SUM(CASE 
            WHEN ib_lower_bound IS NOT NULL THEN ib_lower_bound 
            ELSE 0 
        END) AS lower_bound_total,
        ROW_NUMBER() OVER (ORDER BY hd_demo_sk) AS rn
    FROM household_demographics 
    LEFT JOIN income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY hd_demo_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
sales_summary AS (
    SELECT 
        SUM(ss.net_profit) AS total_net_profit,
        COUNT(ss.ticket_number) AS total_transactions,
        ss.s_sold_date 
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ss.s_sold_date
),
best_sellers AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sold
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY i.i_item_sk, i.i_product_name
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer_info ci
    JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender
    HAVING SUM(ws.ws_net_paid) > 1000
)

SELECT 
    cus.c_first_name,
    cus.c_last_name,
    cus.cd_gender,
    SUM(ss.total_net_profit) AS total_sales_profit,
    COUNT(ss.total_transactions) AS total_transactions,
    AVG(id.upper_bound_total - id.lower_bound_total) AS avg_income_band
FROM top_customers cus
JOIN sales_summary ss ON ss.total_transactions > 0
JOIN income_distribution id ON id.hd_demo_sk = cus.c_customer_sk
GROUP BY cus.c_first_name, cus.c_last_name, cus.cd_gender
ORDER BY total_sales_profit DESC, total_transactions DESC
LIMIT 10;
