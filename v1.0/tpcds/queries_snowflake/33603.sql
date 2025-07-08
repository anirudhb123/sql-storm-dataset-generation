
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
    UNION ALL
    SELECT 
        c.c_customer_sk,
        h.total_sales * 1.1 AS total_sales,
        h.total_transactions + 1 AS total_transactions,
        h.level + 1
    FROM 
        sales_hierarchy h
    JOIN 
        customer c ON h.ss_customer_sk = c.c_customer_sk
    WHERE 
        h.level < 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, ca.ca_city
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.ca_city,
        ci.total_web_sales,
        ci.web_order_count,
        ROW_NUMBER() OVER (PARTITION BY ci.ca_city ORDER BY ci.total_web_sales DESC) AS city_rank
    FROM 
        customer_info ci
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.ca_city,
    tc.total_web_sales,
    tc.web_order_count,
    sh.total_sales AS hierarchy_sales
FROM 
    top_customers tc
JOIN 
    sales_hierarchy sh ON tc.c_customer_sk = sh.ss_customer_sk
WHERE 
    tc.city_rank <= 5
    AND (tc.total_web_sales > 1000 OR tc.web_order_count > 10)
ORDER BY 
    tc.ca_city, tc.total_web_sales DESC;
