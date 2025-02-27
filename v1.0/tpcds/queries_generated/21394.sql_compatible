
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
),
store_sales_summary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS number_of_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
catalog_sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        SUM(CASE WHEN cs.cs_list_price IS NOT NULL THEN cs.cs_list_price ELSE 0 END) AS catalog_sales_value
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
),
final_summary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(ss.total_sales) AS store_total_sales,
        COALESCE(cs.catalog_sales_value, 0) AS catalog_sales_value,
        MAX(CASE WHEN rs.rn = 1 THEN rs.ws_net_profit END) AS max_web_net_profit
    FROM 
        ranked_sales rs
    LEFT JOIN 
        store_sales_summary ss ON rs.ws_item_sk = ss.ss_item_sk
    LEFT JOIN 
        catalog_sales_summary cs ON rs.ws_item_sk = cs.cs_item_sk
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    fa.ws_item_sk,
    fa.store_total_sales,
    fa.catalog_sales_value,
    fa.max_web_net_profit,
    CASE 
        WHEN fa.store_total_sales > fa.catalog_sales_value THEN 'More sales in store'
        ELSE 'More catalog sales'
    END AS sales_comparison,
    CASE 
        WHEN fa.max_web_net_profit IS NULL THEN 'No profit recorded'
        ELSE 'Profit recorded'
    END AS profit_status
FROM 
    final_summary fa
WHERE 
    fa.store_total_sales > 1000
    OR fa.catalog_sales_value > 500
ORDER BY 
    fa.ws_item_sk;
