
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        1 AS hierarchy_level
    FROM store
    WHERE s_number_employees IS NOT NULL
    UNION ALL
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        sh.hierarchy_level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE sh.hierarchy_level < 10
),
ranking AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_return_tax
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.total_return_tax, 0) AS total_return_tax,
    sh.s_store_name,
    sh.hierarchy_level,
    CASE 
        WHEN s.total_sales > 0 THEN 'High Value'
        WHEN s.total_sales BETWEEN 1 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM customer c
LEFT JOIN ranking s ON c.c_customer_sk = s.c_customer_sk
LEFT JOIN return_summary r ON c.c_customer_sk = r.wr_returning_customer_sk
LEFT JOIN sales_hierarchy sh ON c.c_current_addr_sk = sh.s_store_sk
WHERE 
    (c.c_birth_year >= 1975 AND c.c_birth_year <= 1995) OR 
    (c.c_current_cdemo_sk IS NOT NULL AND s.total_sales > 100)
ORDER BY 
    total_sales DESC,
    full_name ASC
LIMIT 50;
