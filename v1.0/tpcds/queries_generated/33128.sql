
WITH RECURSIVE sales_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year >= 2020
    UNION ALL
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year < 2020 AND d_date_sk > (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year >= 2020)
),
customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           COALESCE(sd.ss_total_sales, 0) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT ss_customer_sk, SUM(ss_net_paid) AS ss_total_sales
        FROM store_sales
        WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM sales_dates)
        GROUP BY ss_customer_sk
    ) sd ON c.c_customer_sk = sd.ss_customer_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_purchase_estimate > 500
),
top_customers AS (
    SELECT *,
           RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM customer_data
)
SELECT tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.total_sales,
       (SELECT COUNT(*) FROM top_customers WHERE sales_rank <= 10 AND cd_gender = tc.cd_gender) AS gender_top_count
FROM top_customers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.cd_gender, tc.total_sales DESC
LIMIT 100;

-- Nested Queries and Computation
SELECT c.c_customer_id,
       MAX(ws.ws_net_paid_inc_tax) AS max_payment,
       SUM(CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS shipped_sales,
       SUM(CASE WHEN ws.ws_ship_date_sk IS NULL THEN ws.ws_net_paid ELSE 0 END) AS pending_sales
FROM customer c
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE c.c_first_name IS NOT NULL
GROUP BY c.c_customer_id
HAVING MAX(ws.ws_net_paid_inc_tax) > 1000
ORDER BY max_payment DESC;

-- String manipulation and complex predicates
SELECT DISTINCT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    SUM(ws.ws_quantity) AS total_items,
    SUM(ws.ws_net_paid_inc_tax) AS total_income
FROM customer c
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE (c.c_birth_year BETWEEN 1975 AND 1995) 
  AND (c.c_email_address LIKE '%@example.com' OR c.c_email_address IS NULL)
  AND ws.ws_sold_date_sk > 2458435
GROUP BY full_name
HAVING total_items > 20
ORDER BY total_income DESC
LIMIT 50;
