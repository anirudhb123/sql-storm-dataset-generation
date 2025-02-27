
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        s.ss_sold_date_sk,
        SUM(s.ss_net_paid) AS total_net_paid
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk 
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_year
    UNION ALL
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        s.ss_sold_date_sk,
        SUM(s.ss_net_paid) AS total_net_paid
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON c.c_customer_sk = sh.c_customer_sk
    JOIN 
        store s ON s.s_store_sk = sh.ss_store_sk
    WHERE 
        s.s_closed_date_sk IS NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_year
)
SELECT 
    sh.c_customer_id,
    sh.c_first_name,
    sh.c_last_name,
    YEAR(CURDATE()) - sh.c_birth_year AS age,
    COALESCE(ROUND(SUM(sh.total_net_paid), 2), 0) AS lifetime_value,
    d.d_year,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sh.total_net_paid) DESC) AS rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    date_dim d ON d.d_date_sk = sh.ss_sold_date_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
GROUP BY 
    sh.c_customer_id, sh.c_first_name, sh.c_last_name, sh.c_birth_year, d.d_year
HAVING 
    lifetime_value > (SELECT AVG(total_net_paid) FROM sales_hierarchy)
ORDER BY 
    lifetime_value DESC;
