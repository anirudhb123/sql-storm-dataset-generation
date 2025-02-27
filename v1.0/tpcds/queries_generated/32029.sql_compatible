
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        md.hd_income_band_sk,
        md.hd_buy_potential,
        md.hd_dep_count,
        md.hd_vehicle_count,
        0 AS depth
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics md ON md.hd_demo_sk = c.c_current_hdemo_sk
    WHERE c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        md.hd_income_band_sk,
        md.hd_buy_potential,
        md.hd_dep_count,
        md.hd_vehicle_count,
        sh.depth + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics md ON md.hd_demo_sk = c.c_current_hdemo_sk
    JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_current_addr_sk
    WHERE sh.depth < 3
),
sales_summary AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_gender,
        sh.hd_income_band_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY sh.hd_income_band_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_within_band
    FROM sales_hierarchy sh
    LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_gender,
        sh.hd_income_band_sk
),
best_customers AS (
    SELECT 
        income_band.ib_income_band_sk,
        income_band.ib_lower_bound,
        income_band.ib_upper_bound,
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.total_orders,
        ss.total_profit
    FROM sales_summary ss
    JOIN income_band income_band ON ss.hd_income_band_sk = income_band.ib_income_band_sk
    WHERE ss.rank_within_band = 1
)
SELECT 
    bc.ib_lower_bound,
    bc.ib_upper_bound,
    COUNT(bc.c_customer_sk) AS customer_count,
    SUM(bc.total_profit) AS total_profit_for_band
FROM best_customers bc
GROUP BY 
    bc.ib_lower_bound,
    bc.ib_upper_bound
ORDER BY 
    bc.ib_lower_bound;
