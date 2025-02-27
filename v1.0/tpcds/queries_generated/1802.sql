
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
filtered_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        item.i_brand,
        item.i_category,
        rs.total_quantity,
        rs.total_sales
    FROM 
        ranked_sales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.rank <= 10 
        AND item.i_current_price > 0
), 
sales_summary AS (
    SELECT 
        f.i_item_id,
        f.i_product_name,
        f.i_brand,
        f.i_category,
        f.total_quantity,
        f.total_sales,
        ROUND((f.total_sales / NULLIF(f.total_quantity, 0)), 2) AS avg_sale_per_item
    FROM 
        filtered_sales f
)
SELECT 
    ss.i_product_name,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_sale_per_item,
    COALESCE(ca_state, 'Unknown') AS ship_state,
    CASE 
        WHEN ss.total_sales > 10000 THEN 'High Value'
        WHEN ss.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS sale_category
FROM 
    sales_summary ss
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = ss.i_brand)))
WHERE 
    ss.total_sales IS NOT NULL
ORDER BY 
    ss.total_sales DESC;
