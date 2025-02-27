
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        1 AS level
    FROM 
        customer AS c
    WHERE 
        c.c_birth_month = 12

    UNION ALL

    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.ss_store_sk AS c_current_addr_sk,
        level + 1
    FROM 
        store_sales AS s
    JOIN 
        customer AS c ON s.ss_customer_sk = c.c_customer_sk
    JOIN 
        sales_hierarchy AS sh ON c.c_current_addr_sk = sh.c_current_addr_sk
    WHERE 
        s.ss_sold_date_sk = (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim AS d 
            WHERE 
                d.d_year = YEAR(CURDATE()) 
                AND d.d_month_seq = (
                    SELECT 
                        MAX(d2.d_month_seq) 
                    FROM 
                        date_dim AS d2 
                    WHERE 
                        d2.d_year = YEAR(CURDATE())
                )
        )
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    ca.ca_city,
    COUNT(s.ss_ticket_number) AS total_sales,
    SUM(s.ss_net_paid_inc_tax) AS total_revenue,
    AVG(s.ss_net_profit) AS avg_profit
FROM 
    sales_hierarchy AS sh
LEFT JOIN 
    store_sales AS s ON sh.c_customer_sk = s.ss_customer_sk
LEFT JOIN 
    customer_address AS ca ON sh.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    sh.c_customer_sk, sh.c_first_name, sh.c_last_name, ca.ca_city
HAVING 
    total_revenue IS NOT NULL 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
