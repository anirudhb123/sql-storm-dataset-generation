
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_online_orders,
        SUM(ws.ws_ext_sales_price) AS total_online_revenue
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_online_orders + COUNT(DISTINCT ss.ss_ticket_number) AS total_online_orders,
        sh.total_online_revenue + SUM(ss.ss_ext_sales_price) AS total_online_revenue
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales ss ON sh.c_customer_sk = ss.ss_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
latest_return AS (
    SELECT 
        sr.returning_customer_sk,
        SUM(sr.return_amount) AS total_return_amount,
        COUNT(sr.return_quantity) AS total_return_count
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk = (SELECT MAX(sr2.returned_date_sk) FROM store_returns sr2)
    GROUP BY 
        sr.returning_customer_sk
),
final_sales_data AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_online_orders,
        sh.total_online_revenue,
        COALESCE(lr.total_return_amount, 0) AS total_return_amount,
        COALESCE(lr.total_return_count, 0) AS total_return_count
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        latest_return lr ON sh.c_customer_sk = lr.returning_customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_online_orders,
    fs.total_online_revenue,
    fs.total_return_amount,
    fs.total_return_count,
    CASE 
        WHEN fs.total_online_revenue > 10000 THEN 'High Roller'
        WHEN fs.total_online_revenue BETWEEN 5000 AND 10000 THEN 'Mid Tier'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    final_sales_data fs
WHERE 
    fs.total_online_orders > 5
ORDER BY 
    fs.total_online_revenue DESC;
