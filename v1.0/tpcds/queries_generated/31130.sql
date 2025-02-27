
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) + sh.total_spent AS total_spent
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_current_hdemo_sk IS NOT NULL
)

SELECT 
    c.c_first_name, 
    c.c_last_name, 
    COALESCE(d.d_year, 'UNKNOWN') AS purchase_year,
    COUNT(ss.ss_ticket_number) AS number_of_purchases, 
    SUM(ss.ss_net_paid) AS total_spent,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(d.d_year, 'UNKNOWN') ORDER BY SUM(ss.ss_net_paid) DESC) AS spending_rank
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND 
    ss.ss_net_paid > 0
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_year
HAVING 
    SUM(ss.ss_net_paid) > 1000
ORDER BY 
    total_spent DESC
LIMIT 10

UNION ALL

SELECT 
    'Total' AS c_first_name, 
    NULL AS c_last_name, 
    NULL AS purchase_year,
    COUNT(*) AS number_of_purchases, 
    SUM(ss.ss_net_paid) AS total_spent, 
    NULL AS spending_rank
FROM 
    store_sales ss
WHERE 
    ss.ss_net_paid > 0;
