
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_birth_year >= 1980
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, sh.level + 1
    FROM customer AS c
    JOIN sales_hierarchy AS sh ON c.c_current_addr_sk = sh.c_current_addr_sk
    WHERE sh.level < 5
),
monthly_sales AS (
    SELECT 
        d.d_month_seq, 
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales
    FROM date_dim AS d
    LEFT JOIN web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales AS cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales AS ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_month_seq
),
ranked_sales AS (
    SELECT 
        ms.d_month_seq, 
        ms.total_sales,
        RANK() OVER (ORDER BY ms.total_sales DESC) AS sales_rank
    FROM monthly_sales AS ms
),
customer_sales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.c_current_addr_sk,
        COALESCE(r.total_sales, 0) AS sales_amount,
        r.sales_rank
    FROM sales_hierarchy AS sh
    LEFT JOIN ranked_sales AS r ON r.sales_rank <= 10
)
SELECT 
    sha.c_first_name || ' ' || sha.c_last_name AS customer_name,
    ca.ca_city,
    SUM(sha.sales_amount) AS total_sales,
    COUNT(CASE WHEN sha.sales_amount > 0 THEN 1 END) AS purchase_count,
    AVG(sha.sales_amount) AS avg_sales,
    MAX(sha.sales_amount) AS max_sales,
    MIN(sha.sales_amount) AS min_sales
FROM customer_sales AS sha
INNER JOIN customer_address AS ca ON sha.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA' OR ca.ca_state IS NULL
GROUP BY sha.c_first_name, sha.c_last_name, ca.ca_city
HAVING SUM(sha.sales_amount) > 1000
ORDER BY total_sales DESC;
