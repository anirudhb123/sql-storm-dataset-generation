
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i_category_id, i_category, 1 AS level
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)
    
    UNION ALL
    
    SELECT c.i_category_id, c.i_category, ch.level + 1
    FROM item c
    JOIN CategoryHierarchy ch ON c.i_category_id = ch.i_category_id
)

SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    ROUND(AVG(w.ws_ext_sales_price), 2) AS avg_sales_price,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_cd_purchase_estimate IS NULL THEN 1 ELSE 0 END) AS no_purchase_estimate,
    PERCENT_RANK() OVER (ORDER BY COUNT(DISTINCT w.ws_order_number) DESC) AS sales_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    CategoryHierarchy ch ON ch.i_category_id = w.ws_item_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT w.ws_order_number) > 5
ORDER BY 
    ca.ca_state, unique_customers DESC;
