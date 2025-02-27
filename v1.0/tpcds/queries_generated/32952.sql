
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        s.s_store_sk,
        SUM(ss.net_profit) + sh.total_profit,
        sh.level + 1
    FROM 
        store_sales ss
    INNER JOIN 
        sales_hierarchy sh ON ss.ss_store_sk = sh.ss_store_sk
    INNER JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        s.s_closed_date_sk IS NULL
    GROUP BY 
        s.s_store_sk, sh.total_profit, sh.level
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(sh.total_profit) AS max_store_profit,
    MIN(sh.total_profit) AS min_store_profit,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS popular_items
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    store s ON s.s_store_sk = c.c_customer_sk
LEFT JOIN 
    store_sales ss ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN 
    inventory inv ON inv.inv_warehouse_sk = s.s_store_sk
LEFT JOIN 
    item i ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN 
    sales_hierarchy sh ON sh.ss_store_sk = s.s_store_sk
WHERE 
    ca.ca_state = 'CA'
    AND (cd.cd_purchase_estimate > 100 OR cd.cd_credit_rating IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    avg_purchase_estimate DESC;
