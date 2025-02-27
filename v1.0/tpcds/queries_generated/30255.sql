
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_age AS age,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_age
    HAVING 
        total_spent > 1000
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ss.cs_ext_sales_price) AS total_catalog_sales,
    MAX(s.total_sales) AS max_sales_per_item,
    AVG(hvc.total_spent) AS average_spending
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    sales_cte s ON ss.ss_item_sk = s.ss_item_sk AND s.sales_rank = 1
LEFT JOIN 
    high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
GROUP BY 
    a.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY 
    total_customers DESC;
