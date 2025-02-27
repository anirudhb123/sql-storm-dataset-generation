
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_purchase_estimate,
        0 AS depth
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT 
        sh.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_purchase_estimate,
        depth + 1
    FROM 
        sales_hierarchy sh
    INNER JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_dep_count > 0
),
sales_summary AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.depth,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.depth
),
ranked_sales AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.depth,
        s.total_sales,
        s.total_orders,
        RANK() OVER (PARTITION BY s.depth ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.depth,
    r.total_sales,
    r.total_orders,
    r.sales_rank
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.depth, r.total_sales DESC;
