
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        CAST(1 AS INTEGER) AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        level < 5
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
store_sales_summary AS (
    SELECT
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
),
combined_sales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(w.total_sales, 0) AS total_web_sales,
        COALESCE(s.total_sales, 0) AS total_store_sales,
        (COALESCE(w.total_sales, 0) + COALESCE(s.total_sales, 0)) AS grand_total_sales
    FROM 
        customer c
    LEFT JOIN 
        sales_summary w ON c.c_customer_sk = w.ws_bill_customer_sk
    LEFT JOIN 
        store_sales_summary s ON c.c_customer_sk = s.ss_customer_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_marital_status,
    ch.cd_gender,
    cs.grand_total_sales,
    ROW_NUMBER() OVER (PARTITION BY ch.level ORDER BY cs.grand_total_sales DESC) AS sales_rank
FROM 
    customer_hierarchy ch
JOIN 
    combined_sales cs ON ch.c_customer_sk = cs.c_customer_sk
WHERE 
    cs.grand_total_sales > 1000
ORDER BY 
    ch.level, sales_rank;
