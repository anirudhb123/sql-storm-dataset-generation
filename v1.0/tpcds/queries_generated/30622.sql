
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        CAST(s_store_name AS VARCHAR(100)) AS store_path,
        1 AS level
    FROM 
        store
    WHERE 
        s_number_employees > 0

    UNION ALL

    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_number_employees,
        CONCAT(sh.store_path, ' > ', s.s_store_name) AS store_path,
        sh.level + 1
    FROM 
        store s
    INNER JOIN 
        sales_hierarchy sh ON sh.s_store_sk = s.s_store_sk
    WHERE 
        s.s_number_employees >= sh.s_number_employees
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
sales_summary AS (
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        store_sales ws
    JOIN 
        sales_hierarchy sh ON ws.ss_store_sk = sh.s_store_sk
    GROUP BY 
        sh.s_store_sk, sh.s_store_name
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.order_count, 0) AS store_order_count,
    CASE 
        WHEN t.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_rank
FROM 
    top_customers t
LEFT JOIN 
    sales_summary ss ON t.order_count > 0
ORDER BY 
    t.rank,
    total_sales DESC;
