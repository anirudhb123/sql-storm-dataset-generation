
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2480 AND 2490
    GROUP BY 
        ws_bill_customer_sk
    UNION ALL
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_ext_sales_price) + sh.total_sales,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON sh.customer_sk = s.ss_customer_sk
    GROUP BY 
        s.ss_customer_sk, sh.total_sales, sh.level
),
customer_details AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        sh.total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_hierarchy sh ON c.c_customer_sk = sh.customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cd.total_sales, 0) AS total_sales,
    CASE 
        WHEN cd.total_sales IS NULL THEN 'No Sales'
        WHEN cd.total_sales > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_category
FROM 
    customer_details cd
WHERE 
    cd.cd_gender = 'F' AND
    (cd.cd_marital_status = 'S' OR cd.cd_marital_status IS NULL)
ORDER BY 
    cd.total_sales DESC
LIMIT 10;

-- Benchmark to measure the performance of this query across multiple executions
```
