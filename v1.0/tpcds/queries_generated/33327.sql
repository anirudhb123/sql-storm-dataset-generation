
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, 
        ws_order_number
),
shipping_details AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        sm.sm_type, 
        SUM(ws.ws_ext_shipping_cost) AS total_shipping_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        sm.sm_type
),
aggregated_sales AS (
    SELECT
        sh.ws_item_sk,
        sh.ws_order_number,
        sh.total_sales,
        COALESCE(sd.total_shipping_cost, 0) AS total_shipping_cost,
        sh.total_sales - COALESCE(sd.total_shipping_cost, 0) AS net_sales
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        shipping_details sd ON sh.ws_item_sk = sd.ws_item_sk AND sh.ws_order_number = sd.ws_order_number
),
filtered_sales AS (
    SELECT 
        *, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY net_sales DESC) AS sales_rank
    FROM 
        aggregated_sales
    WHERE 
        net_sales > 100
)

SELECT 
    f.ws_item_sk, 
    f.ws_order_number, 
    f.total_sales, 
    f.total_shipping_cost, 
    f.net_sales
FROM 
    filtered_sales f
WHERE 
    f.sales_rank <= 10
ORDER BY 
    f.net_sales DESC
LIMIT 50
OFFSET 20;
