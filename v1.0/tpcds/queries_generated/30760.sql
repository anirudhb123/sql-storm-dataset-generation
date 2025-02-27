
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_sales,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) + sh.total_sales,
        level + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        customer ch ON sh.c_customer_sk = ch.c_current_cdemo_sk 
    LEFT JOIN 
        store_sales ss ON ch.c_customer_sk = ss.ss_customer_sk
    WHERE 
        sh.level < 3
)

SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    COALESCE(sh.total_sales, 0) AS total_sales,
    COUNT(DISTINCT ss.ss_order_number) AS order_count,
    MAX(ss.ss_sold_date_sk) AS last_order_date,
    AVG(ss.ss_net_profit) OVER (PARTITION BY c.c_customer_sk) AS avg_profit_per_order,
    CASE 
        WHEN MAX(ss.ss_sold_date_sk) IS NULL THEN 'No Orders'
        ELSE 'Active Customer'
    END AS customer_status,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sh.total_sales, 0) DESC) AS sales_rank
FROM 
    customer c 
LEFT JOIN 
    SalesHierarchy sh ON c.c_customer_sk = sh.c_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, sh.total_sales
HAVING 
    sh.total_sales >= (SELECT AVG(total_sales) FROM SalesHierarchy)
ORDER BY 
    sales_rank
LIMIT 50;
