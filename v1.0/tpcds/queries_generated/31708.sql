
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.ss_sold_date_sk,
        SUM(s.ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, s.ss_sold_date_sk
    HAVING 
        SUM(s.ss_sales_price) > 1000
),
top_customers AS (
    SELECT 
        customer_sk,
        c_first_name, 
        c_last_name, 
        RANK() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        sales_hierarchy
    WHERE 
        sales_rank <= 10
),
sales_summary AS (
    SELECT 
        s.ss_sold_date_sk,
        SUM(s.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT s.ss_customer_sk) AS total_customers,
        AVG(s.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk IN (SELECT ss_sold_date_sk FROM sales_hierarchy)
    GROUP BY 
        s.ss_sold_date_sk
)
SELECT 
    s.ss_sold_date_sk,
    s.total_net_profit,
    s.total_customers,
    s.avg_sales_price,
    tc.c_first_name,
    tc.c_last_name
FROM 
    sales_summary s
LEFT JOIN 
    top_customers tc ON tc.customer_sk IN 
        (SELECT DISTINCT c.c_customer_sk 
         FROM customer c 
         JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
         WHERE ss.ss_sold_date_sk = s.ss_sold_date_sk)
ORDER BY 
    s.ss_sold_date_sk DESC;
