
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_manager,
        s_city,
        s_state,
        s_country,
        1 AS level
    FROM store
    WHERE s_state = 'CA'
    UNION ALL
    SELECT 
        s.store_sk,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        s.s_manager,
        s.s_city,
        s.s_state,
        s.s_country,
        sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_manager = sh.s_manager
)
SELECT 
    sh.s_store_name,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss_ticket_number) AS transaction_count,
    ROW_NUMBER() OVER (PARTITION BY sh.s_state ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank,
    CASE
        WHEN sh.s_number_employees IS NULL THEN 'Not Available'
        ELSE CAST(sh.s_number_employees AS VARCHAR)
    END AS employee_count
FROM store_sales 
JOIN sales_hierarchy sh ON store_sales.ss_store_sk = sh.s_store_sk
WHERE ss_sold_date_sk IN (
    SELECT d_date_sk 
    FROM date_dim 
    WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
) 
GROUP BY 
    sh.s_store_name, 
    sh.s_state,
    sh.s_number_employees
HAVING 
    SUM(ss_ext_sales_price) > 100000
ORDER BY 
    total_sales DESC
FETCH FIRST 10 ROWS ONLY;
