
WITH RECURSIVE sales_cte AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_sold
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 100
    UNION ALL
    SELECT cs_item_sk, SUM(cs_quantity) AS total_sold
    FROM catalog_sales
    GROUP BY cs_item_sk
    HAVING SUM(cs_quantity) > 100
),
store_info AS (
    SELECT s_store_sk, s_store_name, s_state, s_city
    FROM store
    WHERE s_number_employees > 10
),
sales_summary AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ss.ss_sales_price) AS total_sales, 
           COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN STORE s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk = (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2)
    AND s.s_state = 'CA'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT *,
           RANK() OVER (PARTITION BY s_state ORDER BY total_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT si.s_store_name, si.s_city, si.s_state,
       ss.c_first_name, ss.c_last_name, 
       ss.total_sales, ss.total_transactions,
       COALESCE(ss.total_transactions / NULLIF(SUM(ss.total_transactions) OVER (PARTITION BY ss.s_state), 0), 1) * 100, 0) AS transaction_percentage,
       ARRAY_AGG(DISTINCT ws.ws_item_sk) AS popular_items
FROM ranked_sales ss
JOIN store_info si ON ss.c_customer_sk = si.s_store_sk
LEFT JOIN sales_cte wc ON wc.ws_item_sk = ss.total_sales
GROUP BY si.s_store_name, si.s_city, si.s_state,
         ss.c_first_name, ss.c_last_name, 
         ss.total_sales
HAVING COUNT(*) > 5
ORDER BY ss.total_sales DESC
LIMIT 10;
