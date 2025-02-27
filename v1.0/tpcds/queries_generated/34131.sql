
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        HD.hd_income_band_sk,
        HD.hd_buy_potential,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        household_demographics HD ON c.c_current_hdemo_sk = HD.hd_demo_sk
    WHERE 
        c.c_birth_year > 1980

    UNION ALL

    SELECT 
        s.ss_customer_sk,
        s.ss_ticket_number,
        NULL AS c_last_name,
        NULL AS c_preferred_cust_flag,
        NULL AS hd_income_band_sk,
        NULL AS hd_buy_potential,
        level + 1
    FROM 
        store_sales s
    INNER JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
    WHERE
        s.ss_sales_price > 100
)

SELECT 
    sh.c_first_name,
    COALESCE(sh.c_last_name, 'N/A') AS c_last_name,
    DENSE_RANK() OVER (PARTITION BY sh.hd_income_band_sk ORDER BY sh.level DESC) AS income_rank,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) OVER (PARTITION BY sh.c_customer_sk) AS total_purchases,
    MAX(CASE 
        WHEN sh.hd_buy_potential IS NOT NULL THEN sh.hd_buy_potential 
        ELSE 'UNKNOWN' END) AS buy_potential,
    (SELECT COUNT(DISTINCT ws_order_number) 
     FROM web_sales 
     WHERE ws_bill_customer_sk = sh.c_customer_sk) AS web_orders
FROM 
    sales_hierarchy sh
LEFT JOIN 
    store_sales ss ON sh.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    sh.c_first_name, sh.c_last_name, sh.hd_income_band_sk
HAVING 
    total_net_profit > 5000
ORDER BY 
    total_net_profit DESC, income_rank
FETCH FIRST 10 ROWS ONLY;
