
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        ws_order_number,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    UNION ALL
    SELECT 
        s.ws_sold_date_sk,
        s.ws_item_sk,
        s.ws_sales_price,
        s.ws_quantity,
        s.ws_net_paid,
        s.ws_order_number,
        level + 1
    FROM 
        web_sales s
    JOIN SalesCTE sc ON s.ws_order_number = sc.ws_order_number
    WHERE 
        level < 10
),
MaxSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_paid) IS NOT NULL
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        maxSales.total_net_paid
    FROM 
        MaxSales maxSales
    JOIN 
        item ON maxSales.ws_item_sk = item.i_item_sk
    ORDER BY 
        maxSales.total_net_paid DESC
    LIMIT 10
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    COALESCE(SUM(cs.cs_net_paid), 0) AS catalog_sales,
    COALESCE(SUM(ss.ss_net_paid), 0) AS store_sales,
    COALESCE(SUM(ws.ws_net_paid), 0) AS web_sales,
    CASE 
        WHEN SUM(cs.cs_net_paid) IS NULL AND SUM(ss.ss_net_paid) IS NOT NULL THEN 'Only Store Sales'
        WHEN SUM(ws.ws_net_paid) IS NOT NULL AND SUM(ss.ss_net_paid) IS NULL THEN 'Only Web Sales'
        ELSE 'Mixed Sales'
    END AS sales_type
FROM 
    TopItems t
LEFT JOIN 
    catalog_sales cs ON t.i_item_sk = cs.cs_item_sk
LEFT JOIN 
    store_sales ss ON t.i_item_sk = ss.ss_item_sk
LEFT JOIN 
    web_sales ws ON t.i_item_sk = ws.ws_item_sk
GROUP BY 
    t.i_item_id, t.i_item_desc
ORDER BY 
    total_net_paid DESC;
