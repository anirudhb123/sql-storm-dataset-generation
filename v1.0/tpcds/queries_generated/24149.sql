
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
        SUM(ws.ws_net_profit) AS web_total_profit,
        SUM(ss.ss_net_profit) AS store_total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
income_distribution AS (
    SELECT 
        hd.hd_income_band_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN hd.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low Income'
            WHEN hd.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_band,
        COUNT(*) AS customer_count
    FROM household_demographics hd
    GROUP BY hd.hd_income_band_sk
),
web_sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2415011 AND 2415075
    GROUP BY ws.ws_sold_date_sk
),
store_sales_summary AS (
    SELECT 
        ss.ss_sold_date_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2415011 AND 2415075
    GROUP BY ss.ss_sold_date_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    id.income_band,
    cs.total_web_orders,
    cs.total_store_orders,
    COALESCE(ws.total_web_sales, 0) AS total_web_sales_period,
    COALESCE(st.total_store_sales, 0) AS total_store_sales_period,
    cs.web_total_profit,
    cs.store_total_profit,
    (cs.web_total_profit + cs.store_total_profit) AS combined_profit
FROM customer_summary cs
LEFT JOIN income_distribution id ON cs.cd_credit_rating IS NOT NULL AND cs.cd_credit_rating <> 'Unrated'
LEFT JOIN web_sales_summary ws ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = ws.ws_bill_customer_sk LIMIT 1)
LEFT JOIN store_sales_summary st ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = st.ss_customer_sk LIMIT 1)
WHERE (cs.total_web_orders > 5 OR cs.total_store_orders > 5) AND 
      (cs.cd_marital_status IS NOT NULL OR cs.cd_marital_status LIKE 'S%')
ORDER BY combined_profit DESC, id.customer_count ASC
LIMIT 100;
