
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, cd.cd_demo_sk, cd.cd_gender, 
           cd.cd_marital_status, 0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_first_name IS NOT NULL AND c.c_last_name IS NOT NULL
    
    UNION ALL 
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, cd.cd_demo_sk, cd.cd_gender, 
           cd.cd_marital_status, ch.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_hierarchy ch ON ch.c_customer_sk = c.c_current_hdemo_sk
    WHERE c.c_current_hdemo_sk IS NOT NULL
),
sales_summary AS (
    SELECT 
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
top_stores AS (
    SELECT s.s_store_sk, s.s_store_name, SUM(ss.ss_sales_price) AS total_store_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
    HAVING SUM(ss.ss_sales_price) > (SELECT AVG(ss_total) FROM (SELECT SUM(ss_sales_price) as ss_total FROM store_sales GROUP BY ss_store_sk) AS avg_sales) 
)
SELECT 
    ch.c_first_name, 
    ch.c_last_name, 
    ch.c_preferred_cust_flag,
    ss.total_sales, 
    ss.order_count,
    ts.total_store_sales,
    CASE 
        WHEN ch.level = 0 THEN 'Individual'
        WHEN ch.level = 1 THEN 'Intermediate'
        ELSE 'Advanced'
    END AS customer_level,
    CONCAT(coalesce(cd.cd_gender, 'N/A'), ' - ', COALESCE(cd.cd_marital_status, 'Unknown')) AS demographics_info
FROM customer_hierarchy ch
LEFT JOIN sales_summary ss ON ss.cd_gender = (CASE WHEN ch.cd_gender = 'M' THEN 'Male' ELSE 'Female' END)
LEFT JOIN top_stores ts ON ts.s_store_sk = (
    SELECT ss.ss_store_sk 
    FROM store_sales ss 
    WHERE ss.ss_ticket_number IN (SELECT DISTINCT sr_ticket_number FROM store_returns sr WHERE sr_returned_date_sk IS NOT NULL)
    LIMIT 1
)
WHERE ch.c_preferred_cust_flag = 'Y' OR ss.total_sales > 1000
ORDER BY ch.c_first_name DESC, ss.total_sales DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
