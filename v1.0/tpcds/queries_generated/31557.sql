
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.order_number,
        ws.item_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        1 AS level
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1990
    GROUP BY 
        ws.order_number, ws.item_sk
    
    UNION ALL
    
    SELECT 
        cs.order_number,
        cs.item_sk,
        SUM(cs.ext_sales_price) AS total_sales,
        sh.level + 1
    FROM 
        catalog_sales cs
    INNER JOIN 
        sales_hierarchy sh ON sh.item_sk = cs.item_sk
    GROUP BY 
        cs.order_number, cs.item_sk
),
sales_summary AS (
    SELECT 
        sh.order_number,
        sh.item_sk,
        sh.total_sales,
        ROW_NUMBER() OVER (PARTITION BY sh.item_sk ORDER BY sh.total_sales DESC) AS rank
    FROM 
        sales_hierarchy sh
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ext_sales_price) AS total_web_sales
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_sales ws ON ws.bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT s.order_number) AS web_orders,
    SUM(a.total_web_sales) AS total_sales,
    MAX(s.total_sales) AS max_sales_per_item,
    MIN(s.total_sales) AS min_sales_per_item,
    AVG(s.total_sales) AS avg_sales_per_item,
    COALESCE(NULLIF(s.rank, 1), 0) AS rank_adjusted
FROM 
    address_summary a
LEFT JOIN 
    sales_summary s ON a.customer_count > 0
GROUP BY 
    a.ca_city
HAVING 
    COUNT(DISTINCT s.order_number) > 5
ORDER BY 
    total_sales DESC;
