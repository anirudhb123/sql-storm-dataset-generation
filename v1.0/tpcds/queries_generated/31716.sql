
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_manager,
        s_division_name,
        1 AS level
    FROM store
    WHERE s_division_name IS NOT NULL
    
    UNION ALL
    
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_number_employees,
        sh.s_manager,
        sh.s_division_name,
        h.level + 1
    FROM store sh
    JOIN sales_hierarchy h ON sh.s_manager = h.s_store_name  -- Recursive join condition
),
sales_summary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ss.s_store_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        SUM(ws.ws_net_paid) AS total_web_sales,
        MAX(ws.ws_net_profit) AS max_web_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_sk
)
SELECT 
    sh.s_store_name,
    sh.s_manager,
    COALESCE(ss.total_sales, 0) AS total_store_sales,
    COALESCE(ss.transaction_count, 0) AS total_transactions,
    COALESCE(ss.avg_sales_price, 0) AS average_sales_price,
    cs.web_sales_count,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.max_web_profit, 0) AS max_web_profit
FROM sales_hierarchy sh
LEFT JOIN sales_summary ss ON sh.s_store_sk = ss.s_store_sk
LEFT JOIN customer_sales cs ON cs.c_customer_sk = (
    SELECT c.c_customer_sk 
    FROM customer c 
    WHERE c.c_current_addr_sk IS NOT NULL 
    ORDER BY RANDOM() 
    LIMIT 1
)
WHERE sh.level <= 3
ORDER BY sh.s_store_name, total_store_sales DESC;
