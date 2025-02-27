
SELECT 
    i.i_item_id,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231 THEN ws.ws_quantity ELSE 0 END) AS total_web_sales,
    SUM(CASE WHEN cs.cs_sold_date_sk BETWEEN 20200101 AND 20201231 THEN cs.cs_quantity ELSE 0 END) AS total_catalog_sales,
    SUM(CASE WHEN ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231 THEN ss.ss_quantity ELSE 0 END) AS total_store_sales
FROM 
    item i
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
LEFT JOIN 
    store_sales ss ON i.i_item_sk = ss.ss_item_sk
GROUP BY 
    i.i_item_id
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC
LIMIT 100;
