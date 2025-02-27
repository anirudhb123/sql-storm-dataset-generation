
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        sh.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_profit * 1.1 AS total_profit,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_current_cdemo_sk
    WHERE 
        sh.level < 5
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        RANK() OVER (ORDER BY COALESCE(SUM(ss.ss_net_profit), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.total_profit,
    ss.total_sales,
    ss.total_transactions,
    ss.sales_rank,
    CASE 
        WHEN ss.total_sales > 10000 THEN 'High Value'
        WHEN ss.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    sales_hierarchy sh
LEFT JOIN 
    sales_summary ss ON sh.c_customer_sk = ss.c_customer_sk
WHERE 
    sh.total_profit IS NOT NULL 
ORDER BY 
    sh.total_profit DESC, 
    ss.sales_rank ASC;
