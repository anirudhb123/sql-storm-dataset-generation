
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COALESCE(s.ws_sales_price, 0) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_year > 1970
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COALESCE(s.ws_sales_price, 0) + sh.total_sales AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE sh.total_sales < 10000
), 
sales_summary AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_gender,
        sh.cd_marital_status,
        SUM(sh.total_sales) AS sales_total,
        COUNT(s.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY sh.cd_gender ORDER BY SUM(sh.total_sales) DESC) AS gender_sales_rank
    FROM sales_hierarchy sh
    LEFT JOIN web_sales s ON sh.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.cd_gender, sh.cd_marital_status
)

SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.sales_total,
    ss.order_count,
    ss.gender_sales_rank,
    CASE 
        WHEN ss.sales_total > 5000 THEN 'High Value'
        WHEN ss.sales_total BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM sales_summary ss
WHERE ss.gender_sales_rank <= 10
ORDER BY ss.gender_sales_rank, ss.sales_total DESC;
