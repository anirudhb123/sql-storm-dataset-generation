
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT max(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_store_sk

    UNION ALL

    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        level + 1
    FROM 
        store_sales ss
    INNER JOIN 
        sales_hierarchy sh ON ss_store_sk = sh.ss_store_sk
    WHERE 
        ss_sold_date_sk = (SELECT max(ss_sold_date_sk) FROM store_sales) - level
    GROUP BY 
        ss_store_sk
),
top_sales AS (
    SELECT 
        ss_store_sk,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        sales_hierarchy
),
item_sales AS (
    SELECT 
        i.i_item_id,
        SUM(ss.ss_net_sales) AS total_item_sales
    FROM 
        item i 
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_id
),
top_items AS (
    SELECT 
        i.i_item_id,
        total_item_sales,
        ROW_NUMBER() OVER (ORDER BY total_item_sales DESC) AS rank
    FROM 
        item_sales i
)
SELECT 
    a.ca_city, 
    a.ca_state, 
    COALESCE(ts.total_sales, 0) AS total_store_sales,
    COALESCE(ti.total_item_sales, 0) AS total_item_sales,
    CASE 
        WHEN ts.rank <= 5 THEN 'Top 5 Store'
        ELSE 'Other Store'
    END AS store_category,
    CASE 
        WHEN ti.rank <= 5 THEN 'Top 5 Item'
        ELSE 'Other Item'
    END AS item_category
FROM 
    customer_address a
LEFT JOIN 
    top_sales ts ON ts.ss_store_sk = a.ca_address_sk
LEFT JOIN 
    top_items ti ON ti.rank = 1  -- Assuming we want the top item only for simplicity
WHERE 
    a.ca_state IS NOT NULL
ORDER BY 
    total_store_sales DESC, 
    total_item_sales DESC;
