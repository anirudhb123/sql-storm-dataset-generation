
WITH RECURSIVE cte_sales AS (
    SELECT ss_store_sk, SUM(ss_sales_price) AS total_sales, COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2458356 AND 2458358
    GROUP BY ss_store_sk
    UNION ALL
    SELECT ss_store_sk, total_sales * 1.1, total_transactions + 1 
    FROM cte_sales
    WHERE total_sales < 10000
),
max_income AS (
    SELECT ib_income_band_sk, MAX(ib_upper_bound) AS max_income
    FROM income_band
    GROUP BY ib_income_band_sk
),
customer_stats AS (
    SELECT c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
ranked_customers AS (
    SELECT cs.*, RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS rank
    FROM customer_stats cs
)
SELECT 
    sa.ss_store_sk,
    sa.total_sales,
    cs.total_spent,
    rg.max_income,
    rc.rank,
    COALESCE(SUM(CASE WHEN cs.cd_marital_status = 'M' THEN cs.total_spent ELSE NULL END), 0) AS married_customers
FROM cte_sales sa
JOIN ranked_customers rc ON sa.ss_store_sk = rc.c_customer_sk
JOIN max_income rg ON rc.cd_marital_status = 'M' 
LEFT JOIN customer_stats cs ON rc.c_customer_sk = cs.c_customer_sk
WHERE sa.total_sales > 5000
GROUP BY sa.ss_store_sk, sa.total_sales, cs.total_spent, rg.max_income, rc.rank
HAVING COUNT(DISTINCT rc.c_customer_sk) > 5
ORDER BY sa.total_sales DESC, rg.max_income DESC;
