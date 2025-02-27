
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_sales_price > 50

    UNION ALL

    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        sh.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesHierarchy sh ON ws_item_sk = sh.cs_item_sk
    WHERE 
        ws_sales_price < 20 AND 
        sh.level < 3
),
TotalSales AS (
    SELECT 
        item.i_item_id,
        COALESCE(SUM(sh.cs_sales_price * sh.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        item
    LEFT JOIN 
        catalog_sales cs ON cs.cs_item_sk = item.i_item_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id
),
FinalSales AS (
    SELECT 
        ts.i_item_id,
        ts.total_catalog_sales,
        ts.total_web_sales,
        ts.catalog_order_count,
        ts.web_order_count,
        CASE 
            WHEN total_catalog_sales > total_web_sales THEN 'Catalog'
            WHEN total_web_sales > total_catalog_sales THEN 'Web'
            ELSE 'Equal'
        END AS predominant_sales_channel
    FROM 
        TotalSales ts
    WHERE 
        ts.sales_rank <= 10
)
SELECT 
    fa.i_item_id,
    fa.total_catalog_sales,
    fa.total_web_sales,
    fa.catalog_order_count,
    fa.web_order_count,
    fa.predominant_sales_channel,
    CASE 
        WHEN fa.total_catalog_sales IS NULL THEN 'No Catalog Sales'
        WHEN fa.total_web_sales IS NULL THEN 'No Web Sales'
        ELSE 'Both Channels Active'
    END AS sales_status
FROM 
    FinalSales fa
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT 
            c.c_current_addr_sk 
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk = (
                SELECT 
                    sr_customer_sk 
                FROM 
                    store_returns 
                WHERE 
                    sr_item_sk = fa.i_item_id 
                LIMIT 1
            )
    )
WHERE 
    ca.ca_state IN ('CA', 'NY')
ORDER BY 
    fa.total_catalog_sales DESC, 
    fa.total_web_sales DESC;
