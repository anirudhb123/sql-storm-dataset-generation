
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_salutation
    HAVING 
        SUM(ss.ss_net_paid) IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_salutation,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        sales_hierarchy sh
    INNER JOIN 
        customer ch ON sh.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN 
        store_sales ss ON ch.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_salutation
    HAVING 
        COUNT(ss.ss_ticket_number) > 0
)

SELECT 
    ROW_NUMBER() OVER (PARTITION BY total_spent ORDER BY total_purchases DESC) AS rn,
    CONCAT(s.c_salutation, ' ', s.c_first_name, ' ', s.c_last_name) AS full_name,
    s.total_spent, 
    s.total_purchases,
    DENSE_RANK() OVER (ORDER BY s.total_spent DESC) AS spending_rank
FROM 
    sales_hierarchy s
WHERE 
    s.total_spent > 0
ORDER BY 
    s.total_spent DESC, 
    s.total_purchases DESC
FETCH FIRST 10 ROWS ONLY;
