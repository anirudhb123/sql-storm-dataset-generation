
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.ss_net_profit,
        1 AS level
    FROM 
        customer c
    INNER JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
        AND ss.ss_net_profit IS NOT NULL
    UNION ALL
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.ss_net_profit,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    INNER JOIN 
        customer c ON c.c_customer_sk = sh.c_customer_sk
    INNER JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_net_profit IS NOT NULL
        AND sh.level < 5
), filtered_returns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
    HAVING 
        SUM(cr_return_amount) > 1000
)
SELECT
    sh.c_first_name,
    sh.c_last_name,
    sh.ss_net_profit,
    fr.total_return_amount,
    fr.total_returns,
    DENSE_RANK() OVER (ORDER BY sh.ss_net_profit DESC) AS rank_profit
FROM 
    sales_hierarchy sh
LEFT JOIN 
    filtered_returns fr ON sh.c_customer_sk = fr.cr_returning_customer_sk
WHERE 
    sh.ss_net_profit > 0
ORDER BY 
    rank_profit
FETCH FIRST 10 ROWS ONLY;
