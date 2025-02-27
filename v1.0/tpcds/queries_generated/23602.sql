
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 0 AND 1000 
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        SUM(cs_quantity) OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) AS rn
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk BETWEEN 500 AND 1500
),
AggregatedSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_transactions,
        AVG(CASE WHEN ss.ss_sales_price IS NOT NULL THEN ss.ss_sales_price ELSE 0 END) AS avg_store_price,
        MAX(ws.ws_ext_sales_price) AS max_web_sale_price,
        MAX(cs.cs_ext_sales_price) AS max_catalog_sale_price
    FROM 
        item 
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON item.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON item.i_item_sk = ss.ss_item_sk
    GROUP BY 
        item.i_item_id, item.i_product_name
)
SELECT 
    ag.i_item_id,
    ag.i_product_name,
    ag.total_web_sales,
    ag.total_catalog_sales,
    ag.total_store_transactions,
    ag.avg_store_price,
    ag.max_web_sale_price,
    ag.max_catalog_sale_price,
    CASE 
        WHEN ag.total_web_sales > ag.total_catalog_sales 
        THEN 'Web Sales Lead'
        WHEN ag.total_web_sales < ag.total_catalog_sales 
        THEN 'Catalog Sales Lead'
        ELSE 'Equal Sales'
    END AS sales_lead
FROM 
    AggregatedSales ag
WHERE 
    ag.total_web_sales > (SELECT AVG(total_web_sales) FROM AggregatedSales) 
    OR
    ag.total_catalog_sales > (SELECT AVG(total_catalog_sales) FROM AggregatedSales)
ORDER BY 
    sales_lead DESC, ag.total_web_sales DESC, ag.total_catalog_sales DESC
LIMIT 10;
