
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        s.ss_item_sk, 
        s.ss_quantity, 
        s.ss_net_paid_inc_tax,
        0 AS level
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL
    
    SELECT 
        sh.c_customer_sk, 
        sh.c_first_name, 
        sh.c_last_name, 
        s.ss_item_sk, 
        s.ss_quantity, 
        s.ss_net_paid_inc_tax,
        level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales s ON sh.ss_item_sk = s.ss_item_sk
    WHERE 
        sh.level < 5
)

SELECT 
    sa.c_first_name,
    sa.c_last_name,
    COALESCE(SUM(sa.ss_net_paid_inc_tax), 0) AS total_net_paid,
    COUNT(DISTINCT sa.ss_item_sk) AS unique_items,
    MAX(sa.ss_quantity) AS max_quantity,
    MIN(sa.ss_quantity) AS min_quantity,
    RANK() OVER (ORDER BY COALESCE(SUM(sa.ss_net_paid_inc_tax), 0) DESC) AS rank
FROM 
    sales_hierarchy sa
GROUP BY 
    sa.c_customer_sk, sa.c_first_name, sa.c_last_name
HAVING 
    total_net_paid > 100.00
ORDER BY 
    total_net_paid DESC
LIMIT 10
```
