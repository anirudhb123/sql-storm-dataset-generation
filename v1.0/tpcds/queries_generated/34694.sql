
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price,
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    
    UNION ALL
    
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS cs_quantity,
        SUM(cs.cs_sales_price) AS cs_sales_price,
        SUM(cs.cs_ext_sales_price) AS cs_ext_sales_price,
        sh.level + 1 AS level
    FROM 
        catalog_sales cs
    JOIN 
        sales_hierarchy sh ON cs.cs_order_number = sh.cs_order_number AND cs.cs_item_sk <> sh.cs_item_sk
    GROUP BY 
        cs.cs_order_number, cs.cs_item_sk, sh.level
),
latest_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank_order
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT
    ia.i_item_id,
    ia.i_product_name,
    COALESCE(late.total_quantity, 0) AS recent_web_sales,
    COALESCE(late.total_profit, 0) AS recent_web_profit,
    COALESCE(sale_total.cs_quantity, 0) AS catalog_quantity,
    sale_total.cs_sales_price,
    (CASE 
        WHEN late.total_profit IS NULL THEN 'No Sales'
        WHEN late.total_profit > 1000 THEN 'High Profit'
        ELSE 'Moderate Profit'
    END) AS profit_category
FROM 
    item ia
LEFT JOIN latest_sales late ON ia.i_item_sk = late.ws_item_sk AND late.rank_order = 1
LEFT JOIN (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS cs_quantity,
        SUM(cs.cs_ext_sales_price) AS cs_sales_price
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
) sale_total ON ia.i_item_sk = sale_total.cs_item_sk
WHERE 
    ia.i_current_price IS NOT NULL
AND 
    ia.i_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_item_sk IS NOT NULL)
ORDER BY 
    recent_web_sales DESC, recent_web_profit DESC;
