
WITH RECURSIVE Sales_Hierarchy AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_quantity,
        ss_net_paid,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL
    
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_quantity + sh.ss_quantity,
        CASE WHEN sh.ss_net_paid IS NULL THEN sh.ss_net_paid ELSE sh.ss_net_paid + sh.ss_net_paid END,
        level + 1
    FROM 
        store_sales sh
    JOIN 
        Sales_Hierarchy shier ON sh.ss_store_sk = shier.ss_store_sk AND sh.ss_item_sk = shier.ss_item_sk
    WHERE 
        level < 5 
)
SELECT 
    ca_state AS location,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    MAX(ss_net_paid) AS highest_net_paid,
    AVG(ss_quantity) AS average_quantity
FROM 
    Sales_Hierarchy sh
JOIN 
    customer c ON sh.ss_store_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    (ss_net_paid > 100 OR ss_quantity > 10) 
    AND cd.cd_marital_status IS NOT NULL
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_sk) > 10 
ORDER BY 
    total_customers DESC
LIMIT 10;
