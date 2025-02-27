
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.ss_net_paid, 0) AS total_sales,
        1 AS level
    FROM 
        customer c 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(ss.ss_net_paid, 0) + sh.total_sales AS total_sales,
        sh.level + 1
    FROM 
        sales_hierarchy sh 
    JOIN 
        customer ch ON ch.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN 
        store_sales ss ON ch.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    ca.ca_city,
    SUM(sh.total_sales) AS total_sales_by_city,
    COUNT(DISTINCT sh.c_customer_sk) AS customer_count,
    AVG(sh.total_sales) AS avg_sales_per_customer,
    MAX(sh.total_sales) AS max_sales_per_customer
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    sales_hierarchy sh ON sh.c_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    SUM(sh.total_sales) > 10000
ORDER BY 
    total_sales_by_city DESC;

-- Additional test cases with JOIN on NULL values
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(rs.rs_net_loss), 0) AS total_net_loss
FROM 
    customer c
LEFT JOIN 
    (SELECT 
        sr_refunded_customer_sk,
        SUM(sr_net_loss) AS rs_net_loss
    FROM 
        store_returns
    GROUP BY 
        sr_refunded_customer_sk) AS rs 
ON 
    c.c_customer_sk = rs.sr_refunded_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name
HAVING 
    total_net_loss < 5000
ORDER BY 
    total_net_loss ASC;
