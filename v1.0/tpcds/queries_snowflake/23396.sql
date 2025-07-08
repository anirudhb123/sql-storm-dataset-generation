
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
store_summary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_net_paid_inc_tax) AS store_sales,
        COUNT(DISTINCT ss_ticket_number) AS store_order_count
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
combined_sales AS (
    SELECT 
        item.i_item_id,
        COALESCE(ws.total_quantity, 0) AS web_quantity,
        COALESCE(ws.total_sales, 0) AS web_sales,
        COALESCE(ss.store_quantity, 0) AS store_quantity,
        COALESCE(ss.store_sales, 0) AS store_sales,
        CASE 
            WHEN COALESCE(ws.total_sales, 0) > COALESCE(ss.store_sales, 0) THEN 'Web Dominant'
            WHEN COALESCE(ws.total_sales, 0) < COALESCE(ss.store_sales, 0) THEN 'Store Dominant'
            ELSE 'Equal Sales'
        END AS sales_comparison
    FROM 
        item
    LEFT JOIN 
        sales_summary ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        store_summary ss ON item.i_item_sk = ss.ss_item_sk
),
item_analysis AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY sales_comparison ORDER BY web_sales + store_sales DESC) AS rank
    FROM 
        combined_sales
)
SELECT 
    ca.ca_address_id,
    ci.c_first_name,
    ci.c_last_name,
    ia.i_item_id,
    ia.web_quantity,
    ia.store_quantity,
    ia.web_sales,
    ia.store_sales,
    ia.sales_comparison,
    ia.rank
FROM 
    item_analysis ia
JOIN 
    customer ci ON RANDOM() < 0.1 AND ci.c_customer_sk IN (SELECT c_customer_sk FROM customer WHERE ci.c_customer_sk IS NOT NULL)
JOIN 
    customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
WHERE 
    (ia.web_quantity + ia.store_quantity) >= 10 OR ia.sales_comparison = 'Equal Sales'
ORDER BY 
    ia.rank,
    ca.ca_city ASC, 
    ia.web_sales DESC
LIMIT 100;
