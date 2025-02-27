
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        i.i_current_price AS current_price,
        i.i_brand AS brand,
        0 AS level
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)

    UNION ALL

    SELECT 
        ih.item_sk,
        ih.item_desc,
        ih.current_price * 1.1 AS current_price, 
        ih.brand,
        ih.level + 1
    FROM 
        ItemHierarchy ih
    JOIN 
        (SELECT DISTINCT i_item_sk AS item_sk, 
            i_item_desc, 
            i_current_price, 
            i_brand 
         FROM item 
         WHERE i_rec_start_date <= CURRENT_DATE AND 
         (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE) 
         AND i_current_price IS NOT NULL) AS next_level 
    ON ih.item_sk = next_level.item_sk 
    WHERE ih.level < 5
)
SELECT 
    ca.ca_address_id, 
    ca.ca_city, 
    ca.ca_state, 
    css.total_sales, 
    css.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY css.total_sales DESC) AS sales_rank
FROM 
    customer_address ca
LEFT JOIN (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_paid) AS total_sales, 
        SUM(ss_quantity) AS total_quantity
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        ss_store_sk
) css ON css.ss_store_sk = ca.ca_address_sk
WHERE 
    ca.ca_city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_state = 'CA')
AND 
    (SELECT COUNT(*) FROM ItemHierarchy) > 10 
ORDER BY 
    sa.sales_rank 
FETCH FIRST 10 ROWS ONLY;
