
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_product_name,
        i_category,
        i_brand,
        i_class,
        i_rec_start_date,
        i_rec_end_date,
        1 AS level
    FROM 
        item
    WHERE 
        i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)
    
    UNION ALL
    
    SELECT 
        i.item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_rec_start_date,
        i.i_rec_end_date,
        ih.level + 1
    FROM 
        item i
    JOIN 
        ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk -- Recursive join based on some hierarchy (example)
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
)
SELECT 
    ca.city,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_spent,
    COUNT(DISTINCT ss.ss_ticket_number) AS purchases,
    COUNT(DISTINCT ws.ws_order_number) AS online_purchases,
    ROW_NUMBER() OVER (PARTITION BY ca.city ORDER BY total_spent DESC) AS rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk AND ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk AND ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
LEFT JOIN 
    ItemHierarchy ih ON ss.ss_item_sk = ih.i_item_sk
GROUP BY 
    ca.city, c.c_first_name, c.c_last_name
HAVING 
    COALESCE(SUM(ss.ss_net_paid), 0) > 1000
ORDER BY 
    ca.city, total_spent DESC;
