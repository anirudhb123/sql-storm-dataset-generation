
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        ss_quantity,
        ss_sales_price,
        ss_net_paid,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL
    
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.quantity,
        ss.sales_price,
        ss.net_paid,
        level + 1
    FROM 
        store_sales ss
    JOIN 
        sales_cte s ON ss.item_sk = s.item_sk
    WHERE 
        ss.sold_date_sk < s.sold_date_sk
)

SELECT 
    ca.city,
    SUM(s.quantity) AS total_quantity,
    SUM(s.net_paid) AS total_sales,
    ROUND(AVG(s.sales_price), 2) AS avg_sales_price,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM 
    sales_cte s
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = s.customer_sk LIMIT 1)
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = s.customer_sk LIMIT 1)
WHERE 
    cd.cd_marital_status = 'M'
    AND (s.sales_price BETWEEN 20 AND 100 OR s.quantity > 5)
GROUP BY 
    ca.city
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
