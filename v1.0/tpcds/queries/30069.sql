
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c_preferred_cust_flag,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
)

SELECT 
    ca.ca_city,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    COUNT(DISTINCT sh.c_customer_sk) AS unique_customers,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rank,
    COALESCE(MAX(cd.cd_purchase_estimate), 0) AS max_purchase_estimate,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk IN (SELECT DISTINCT c_customer_sk FROM sales_hierarchy)) AS total_web_sales
FROM 
    store_sales ss
LEFT JOIN 
    customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_hierarchy sh ON ss.ss_customer_sk = sh.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON sh.c_customer_sk = cd.cd_demo_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231 
    AND cd.cd_gender = 'F' 
    AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status <> 'S')
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ss.ss_net_paid_inc_tax) > 1000
ORDER BY 
    total_sales DESC
FETCH FIRST 10 ROWS ONLY;
