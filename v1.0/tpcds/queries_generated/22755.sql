
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_preferred_cust_flag,
           CAST(c_first_name AS VARCHAR(100)) AS full_name,
           1 AS level
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_preferred_cust_flag,
           CONCAT(ch.full_name, ' -> ', c.c_first_name) AS full_name,
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_addr_sk
    WHERE ch.level < 5
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid_inc_tax) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459000 AND 2459060 -- arbitrary date range
    GROUP BY ws_bill_customer_sk
),
demographic_stats AS (
    SELECT cd.cd_gender,
           SUM(ws.ws_net_profit) AS profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           AVG(cd.cd_credit_rating) AS avg_ranking
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
    GROUP BY cd.cd_gender
)
SELECT ch.full_name,
       ss.total_sales,
       ss.order_count,
       ds.profit AS gender_profit,
       ds.order_count AS gender_order_count,
       CASE 
           WHEN ss.total_sales IS NOT NULL THEN 
               ROUND((ds.profit / ss.total_sales) * 100, 2) 
           ELSE 0 
       END AS profit_percentage
FROM customer_hierarchy ch
FULL OUTER JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN demographic_stats ds ON ds.cd_gender = 
    (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = ch.c_customer_sk)
WHERE ch.level = 1 OR ss.order_count > 5
ORDER BY profit_percentage DESC NULLS LAST;
