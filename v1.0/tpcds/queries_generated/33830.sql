
WITH RECURSIVE category_hierarchy AS (
    SELECT i_category_id, i_category, 0 AS level
    FROM item
    WHERE i_category_id IS NOT NULL
    UNION ALL
    SELECT i_category_id, CONCAT('Subcategory of ', i_category), level + 1
    FROM item
    WHERE i_category_id IS NOT NULL
    AND level < 3
)
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT CONCAT(i_category, ' (', COUNT(i_item_sk), ')')) AS item_summary
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    inventory inv ON ws.ws_item_sk = inv.inv_item_sk 
LEFT JOIN 
    category_hierarchy ch ON inv.inv_item_sk = ch.i_category_id
WHERE 
    ca_state IS NOT NULL
    AND cd_purchase_estimate > 100 
    AND cd_marital_status IN ('M', 'S')
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    customer_count DESC;
