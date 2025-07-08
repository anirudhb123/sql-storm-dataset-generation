
WITH customer_stats AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           SUM(ws.ws_sales_price) AS total_spent,
           DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_marital_status IS NOT NULL 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name || ' ' || c.c_last_name AS full_name, 
           cs.total_spent
    FROM customer_stats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.spending_rank <= 10
)
SELECT tc.full_name, 
       tc.total_spent, 
       COALESCE((
           SELECT COUNT(*) 
           FROM store_sales ss 
           WHERE ss.ss_customer_sk = tc.c_customer_sk AND ss.ss_sales_price IS NOT NULL
       ), 0) AS store_sales_count,
       COALESCE((
           SELECT COUNT(*) 
           FROM catalog_sales cs 
           WHERE cs.cs_bill_customer_sk = tc.c_customer_sk AND cs.cs_sales_price IS NOT NULL
       ), 0) AS catalog_sales_count,
       CASE 
           WHEN tc.total_spent > 1000 THEN 'High Roller'
           WHEN tc.total_spent > 500 THEN 'Mid Tier'
           ELSE 'Low Spender'
       END AS customer_category
FROM top_customers tc
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca
    WHERE ca.ca_address_sk = (
        SELECT c.c_current_addr_sk
        FROM customer c
        WHERE c.c_customer_sk = tc.c_customer_sk
    ) AND ca.ca_country = 'USA'
)
ORDER BY tc.total_spent DESC;
