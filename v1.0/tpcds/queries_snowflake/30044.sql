
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_cdemo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        1 AS level
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_gender = 'F' AND
        cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_hierarchy sh ON sh.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND 
                d_month_seq BETWEEN 1 AND 6
        )
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    COUNT(s.ss_item_sk) AS total_items_sold,
    SUM(s.ss_net_paid) AS total_revenue,
    AVG(s.ss_net_paid) AS avg_order_value,
    COUNT(DISTINCT s.ss_ticket_number) AS unique_orders
FROM 
    sales_hierarchy sh
LEFT JOIN 
    store_sales s ON sh.c_customer_sk = s.ss_customer_sk
GROUP BY 
    sh.c_first_name, 
    sh.c_last_name
HAVING 
    SUM(s.ss_net_paid) > (SELECT AVG(ss_net_paid) FROM store_sales) 
ORDER BY 
    total_revenue DESC
LIMIT 10;
