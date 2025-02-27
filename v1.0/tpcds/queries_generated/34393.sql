
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        0 AS level,
        '' AS path
    FROM 
        customer AS c
    WHERE 
        c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1,
        CONCAT(sh.path, ' -> ', c.c_first_name, ' ', c.c_last_name)
    FROM 
        sales_hierarchy AS sh
    JOIN 
        store_sales AS s ON sh.c_customer_sk = s.ss_customer_sk
    JOIN 
        customer AS c ON s.ss_customer_sk = c.c_customer_sk
)
SELECT 
    sh.level,
    COUNT(DISTINCT sh.c_customer_sk) AS unique_customers,
    STRING_AGG(DISTINCT sh.path) AS customer_paths
FROM 
    sales_hierarchy AS sh
GROUP BY 
    sh.level
HAVING 
    COUNT(DISTINCT sh.c_customer_sk) > 1
ORDER BY 
    sh.level DESC;

SELECT 
    COUNT(DISTINCT wr.wr_returning_customer_sk) AS unique_returning_customers,
    AVG(wr.w_return_amt) AS avg_return_amt,
    AVG(wr.w_return_tax) AS avg_return_tax
FROM 
    web_returns AS wr
LEFT JOIN 
    customer AS c ON wr.w_returning_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_country IS NOT NULL
    AND (c.c_birth_year < 1990 OR c.c_birth_year IS NULL)
    AND wr.w_return_quantity > 0
    AND wr.w_return_amt IS NOT NULL
GROUP BY 
    c.c_birth_country;

SELECT 
    d.d_year,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_customer_sk) AS total_customers
FROM 
    date_dim AS d
INNER JOIN 
    store_sales AS ss ON d.d_date_sk = ss.ss_sold_date_sk
WHERE 
    d.d_year BETWEEN 2010 AND 2020
GROUP BY 
    d.d_year
HAVING 
    SUM(ss.ss_net_paid_inc_tax) > (SELECT AVG(ss1.ss_net_paid_inc_tax)
                                     FROM store_sales AS ss1
                                     INNER JOIN date_dim AS d1 ON ss1.ss_sold_date_sk = d1.d_date_sk
                                     WHERE d1.d_year BETWEEN 2010 AND 2020);
