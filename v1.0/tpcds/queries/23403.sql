
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
           NULL AS parent_customer_id, 0 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
           ch.c_customer_sk AS parent_customer_id, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_info AS (
    SELECT ss.ss_item_sk, ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_quantity,
           SUM(ss.ss_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ss.ss_item_sk, ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_quantity
),
customer_rank AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           DENSE_RANK() OVER (PARTITION BY ch.parent_customer_id ORDER BY SUM(si.total_sales) DESC) AS rank
    FROM customer_hierarchy ch
    LEFT JOIN sales_info si ON ch.c_customer_sk = si.ss_store_sk
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.parent_customer_id
)
SELECT c.c_first_name, c.c_last_name, CR.rank,
       COALESCE(SUM(si.total_sales), 0) AS total_sales,
       CASE 
           WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
           WHEN c.c_preferred_cust_flag = 'N' THEN 'Non-Preferred'
           ELSE 'Unknown' 
       END AS cust_flag_status
FROM customer c
LEFT JOIN customer_rank CR ON c.c_customer_sk = CR.c_customer_sk
LEFT JOIN sales_info si ON c.c_customer_sk = si.ss_store_sk
GROUP BY c.c_first_name, c.c_last_name, CR.rank, c.c_preferred_cust_flag
HAVING COALESCE(SUM(si.total_sales), 0) > 1000
ORDER BY total_sales DESC, cust_flag_status, CR.rank NULLS LAST;
