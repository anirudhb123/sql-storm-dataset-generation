
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c_last_review_date_sk,
        1 AS hierarchy_level
    FROM 
        customer c
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c_last_review_date_sk,
        sh.hierarchy_level + 1
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
),
avg_sales AS (
    SELECT 
        ws_bill_customer_sk,
        AVG(ws_net_paid) AS avg_net_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        coalesce(({SELECT AVG(ws_net_paid) 
                   FROM web_sales 
                   WHERE ws_bill_customer_sk = c.c_customer_sk
                   GROUP BY ws_bill_customer_sk}), 0) AS avg_net_paid,
        ROW_NUMBER() OVER (ORDER BY coalesce(({SELECT AVG(ws_net_paid) 
                                                FROM web_sales 
                                                WHERE ws_bill_customer_sk = c.c_customer_sk
                                                GROUP BY ws_bill_customer_sk}), 0) DESC) AS rn
    FROM 
        customer c
    JOIN 
        avg_sales a ON c.c_customer_sk = a.ws_bill_customer_sk
    WHERE 
        a.avg_net_sales > 1000
)
SELECT 
    tc.full_name,
    tc.avg_net_paid,
    sh.hierarchy_level,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(CASE WHEN ws.ws_net_paid > 0 THEN 1 ELSE 0 END) AS positive_sales_count
FROM 
    top_customers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    sales_hierarchy sh ON sh.c_customer_sk = tc.c_customer_sk
WHERE 
    tc.rn <= 10
GROUP BY 
    tc.full_name,
    tc.avg_net_paid,
    sh.hierarchy_level
ORDER BY 
    tc.avg_net_paid DESC;
