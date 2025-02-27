
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ss.store_sk,
        ss_sold_date_sk,
        ss_item_sk,
        ss_quantity,
        ss_ext_sales_price,
        ss_net_profit,
        1 AS level
    FROM 
        store_sales ss
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2)

    UNION ALL

    SELECT 
        sh.store_sk,
        ss.sold_date_sk,
        ss.item_sk,
        ss.quantity,
        ss.ext_sales_price,
        ss.net_profit + sh.net_profit AS net_profit,
        level + 1
    FROM 
        store_sales ss
    JOIN 
        SalesHierarchy sh ON ss.store_sk = sh.store_sk AND sh.level < 4
)

SELECT 
    ca.city, 
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(sh.ss_quantity) AS total_quantity,
    AVG(sh.ss_net_profit) AS avg_net_profit,
    STRING_AGG(DISTINCT cd.education_status) AS unique_educational_backgrounds
FROM 
    SalesHierarchy sh
JOIN 
    customer c ON c.c_customer_sk = sh.ss_customer_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (c.c_birth_year BETWEEN 1980 AND 2000 OR c.c_preferred_cust_flag = 'Y')
GROUP BY 
    ca.city
HAVING 
    COUNT(DISTINCT c.customer_id) > 5 
    AND SUM(sh.ss_net_profit) > 1000.00
ORDER BY 
    total_quantity DESC, avg_net_profit DESC;
