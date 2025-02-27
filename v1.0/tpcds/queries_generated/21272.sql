
WITH RECURSIVE sales_leaderboard AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
           SUM(s.ss_net_paid) AS total_amount,
           RANK() OVER (ORDER BY SUM(s.ss_net_paid) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE c.c_birth_year IS NOT NULL AND 
          (c.c_birth_month BETWEEN 1 AND 12 OR COALESCE(c.c_birth_month, 0) = 0)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address,
           CASE 
               WHEN cd.cd_credit_rating = 'Excellent' THEN 'Gold'
               WHEN cd.cd_credit_rating = 'Good' THEN 'Silver'
               ELSE 'Bronze'
           END AS customer_tier
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 10000 AND cd.cd_gender = 'F'
),
sales_per_state AS (
    SELECT w.w_state,
           SUM(s.ss_net_paid) AS total_sales_amount
    FROM warehouse w
    JOIN store s ON w.w_warehouse_sk = s.s_store_sk
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY w.w_state
)
SELECT hlc.c_first_name,
       hlc.c_last_name,
       hlc.c_email_address,
       hlc.customer_tier,
       sl.total_sales,
       sl.total_amount,
       sps.total_sales_amount AS state_sales
FROM high_value_customers hlc
JOIN sales_leaderboard sl ON hlc.c_customer_sk = sl.c_customer_sk
LEFT JOIN sales_per_state sps ON sps.total_sales_amount IS NOT NULL
WHERE (sl.total_sales > 10 OR hlc.customer_tier = 'Gold')
  AND (sps.total_sales_amount IS NULL OR sps.total_sales_amount > 50000)
ORDER BY hlc.customer_tier DESC, sl.total_amount DESC
FETCH FIRST 10 ROWS ONLY;

SELECT DISTINCT ca_state
FROM customer_address AS ca
WHERE ca_zip IS NOT NULL
UNION
SELECT DISTINCT w_state
FROM warehouse
WHERE w_zip IS NULL AND w_country = 'USA'
ORDER BY 1;
