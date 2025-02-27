
WITH RECURSIVE address_hierarchy AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        ca_city,
        ca_state,
        ca_country,
        0 as level
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL

    UNION ALL

    SELECT 
        ca.ca_address_sk,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ah.level + 1
    FROM 
        customer_address ca
    JOIN 
        address_hierarchy ah ON ca.ca_state = ah.ca_state
    WHERE 
        ah.level < 3
)
SELECT 
    cd_gender,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(CASE 
        WHEN cd_marital_status = 'M' THEN 1 
        ELSE 0 
    END) AS married_count,
    SUM(CASE 
        WHEN cd_marital_status = 'S' THEN i.i_current_price ELSE 0 
    END) AS single_items_value,
    AVG(CASE 
        WHEN ca_country IS NULL THEN 0 
        ELSE ca_zip 
    END) AS avg_zip,
    ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY COUNT(DISTINCT c.c_customer_id) DESC) AS gender_rank
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    inventory inv ON inv.inv_item_sk = (SELECT TOP 1 i_item_sk FROM item i ORDER BY NEWID())
LEFT JOIN 
    (
        SELECT 
            wp.web_page_id, 
            COUNT(DISTINCT wr_order_number) AS web_return_count 
        FROM 
            web_returns wr 
        INNER JOIN 
            web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk 
        GROUP BY 
            wp.web_page_id
    ) AS return_data ON return_data.web_page_id = c.c_customer_id
JOIN 
    address_hierarchy ah ON ah.ca_city = ca.ca_city AND ah.ca_state = ca.ca_state
WHERE 
    cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
GROUP BY 
    cd_gender
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY 
    customer_count DESC
LIMIT 10;
