
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        1 AS level
    FROM customer c
    WHERE c.c_birth_year > 1980
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE c.c_birth_year > 1980
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_income_band_sk IS NOT NULL THEN 'Has Income Data' 
            ELSE 'No Income Data'
        END AS income_status
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
final_summary AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_status,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(ss.total_profit, 0.00) AS total_profit
    FROM customer_hierarchy ch
    JOIN customer_details cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    f.income_status,
    f.order_count,
    f.total_profit,
    ROW_NUMBER() OVER (PARTITION BY f.cd_gender ORDER BY f.total_profit DESC) AS rank_within_gender
FROM final_summary f
WHERE f.order_count > 5
ORDER BY f.total_profit DESC, f.c_last_name ASC
LIMIT 100;
