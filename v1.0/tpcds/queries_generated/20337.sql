
WITH ranked_sales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rank_sales,
        SUM(ws_quantity) OVER (PARTITION BY ws_order_number) AS total_quantity,
        CASE 
            WHEN SUM(ws_quantity) OVER (PARTITION BY ws_order_number) = 0 THEN NULL
            ELSE SUM(ws_quantity * ws_sales_price) OVER (PARTITION BY ws_order_number) / NULLIF(SUM(ws_quantity) OVER (PARTITION BY ws_order_number), 0)
        END AS avg_price_per_order
    FROM 
        web_sales
)
SELECT 
    ws.web_order_number,
    COALESCE(AVG(ws_sales.sales_price), 0) AS avg_sales_price,
    SUM(ws.sales_quantity) AS total_items_sold,
    wd.d_date AS sale_date,
    CASE 
        WHEN wd.d_holiday = 'Y' THEN 'Holiday'
        ELSE 'Non-Holiday'
    END AS sale_type,
    COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_ship_modes,
    COUNT(DISTINCT ws.ws_web_page_sk) FILTER (WHERE ws.ws_ship_mode_sk IS NOT NULL) AS webpage_count
FROM 
    web_sales ws
JOIN 
    date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
LEFT JOIN 
    ranked_sales rs ON ws.ws_order_number = rs.ws_order_number
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = ws.ws_bill_customer_sk)
WHERE 
    (wd.d_year = 2023 AND wd.d_moy IN (1, 6, 12))
    OR (ws.ws_quantity > 5 AND ws_sales_price BETWEEN 20 AND 100)
GROUP BY 
    ws.web_order_number, wd.d_date
HAVING 
    SUM(ws_sales_price) > 500
    AND COUNT(DISTINCT ca.ca_city) > 1
ORDER BY 
    wd.d_date DESC, total_items_sold DESC
FETCH FIRST 100 ROWS ONLY;
