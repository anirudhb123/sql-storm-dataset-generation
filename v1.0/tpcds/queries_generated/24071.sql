
WITH recursive customer_sales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_paid) AS total_sales,
           ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_sales,
           DENSE_RANK() OVER(ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE total_sales IS NOT NULL
),
discounted_sales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY ws.ws_item_sk
)
SELECT DISTINCT c.c_customer_id, 
                c.c_first_name, 
                c.c_last_name,
                COALESCE(ts.total_sales, 0) AS total_sales,
                STRING_AGG(DISTINCT CONCAT_WS(' - ', i.i_item_desc, ds.total_discount::TEXT)) AS discounts
FROM customer c
LEFT JOIN top_customers tc ON c.c_customer_sk = tc.c_customer_sk AND tc.sales_rank <= 10
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN discounted_sales ds ON ds.ws_item_sk = ws.ws_item_sk
WHERE c.c_birth_year IS NOT NULL AND (c.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE) OR c.c_birth_month IS NULL)
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
HAVING total_sales > (SELECT AVG(total_sales) FROM top_customers WHERE sales_rank <= 10)
ORDER BY total_sales DESC
LIMIT 50;
