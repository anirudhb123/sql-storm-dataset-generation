
WITH RECURSIVE item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    WHERE 
        ws_sold_date_sk >= 20200101 
    GROUP BY 
        ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        SUM(cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM
        catalog_sales
    WHERE 
        cs_sold_date_sk >= 20200101 
    GROUP BY 
        cs_item_sk
),
popular_items AS (
    SELECT 
        i_item_sk,
        SUM(total_sales) AS overall_sales,
        SUM(order_count) AS overall_orders
    FROM (
        SELECT ws_item_sk, total_sales, order_count FROM item_sales
        UNION ALL
        SELECT cs_item_sk, total_sales, order_count FROM item_sales
    ) AS combined_sales
    GROUP BY i_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_brand,
        item.i_current_price,
        popular.overall_sales,
        popular.overall_orders,
        ROW_NUMBER() OVER (ORDER BY popular.overall_sales DESC) AS rank
    FROM 
        item AS item
    JOIN
        popular_items AS popular ON item.i_item_sk = popular.i_item_sk
)
SELECT 
    t1.*, 
    (CASE 
        WHEN t1.overall_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('Sales Count: ', t1.overall_orders)
    END) AS sales_info,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_item_sk = t1.i_item_sk AND ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231) AS store_sales_count
FROM 
    top_items t1
WHERE 
    t1.rank <= 10
ORDER BY 
    t1.overall_sales DESC;
