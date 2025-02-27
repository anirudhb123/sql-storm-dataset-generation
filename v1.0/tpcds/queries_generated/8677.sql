
WITH RankedItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY cat.cat_department ORDER BY SUM(ss.ss_quantity) DESC) AS rnk,
        cat.cat_department
    FROM 
        item i
    JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    JOIN 
        catalog_page cat ON cs.cs_catalog_page_sk = cat.cp_catalog_page_sk
    JOIN 
        store_sales ss ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN 1 AND 365 
        AND ss.ss_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, cat.cat_department
),
TopItems AS (
    SELECT 
        r.* 
    FROM 
        RankedItems r
    WHERE 
        r.rnk <= 5
)
SELECT 
    ci.ca_city,
    ti.i_item_id,
    ti.i_item_desc,
    ti.i_current_price,
    COUNT(*) AS total_sales,
    AVG(ss.ss_net_profit) AS average_profit
FROM 
    TopItems ti
JOIN 
    store_sales ss ON ti.i_item_sk = ss.ss_item_sk
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ci.ca_city, ti.i_item_id, ti.i_item_desc, ti.i_current_price
ORDER BY 
    total_sales DESC, ci.ca_city
LIMIT 100;
