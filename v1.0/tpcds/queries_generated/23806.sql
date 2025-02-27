
WITH ranked_sales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
total_sales AS (
    SELECT 
        ws_order_number,
        SUM(ws_sales_price) AS total_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_order_number
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        COALESCE(i_current_price, 0) AS current_price,
        CASE 
            WHEN i_current_price IS NULL THEN 'Missing Price'
            ELSE 'Available'
        END AS price_status
    FROM 
        item
)
SELECT 
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    COALESCE(ts.total_sales_price, 0) AS total_spent,
    id.i_item_desc,
    id.current_price,
    CASE 
        WHEN rs.rn = 1 THEN 'Most Expensive Item'
        ELSE 'Other Item'
    END AS item_category,
    COALESCE(SUM(CASE WHEN ws_ext_discount_amt > 0 THEN 1 END), 0) AS discount_count
FROM 
    customer AS cust
LEFT JOIN 
    ranked_sales AS rs ON cust.c_customer_sk = rs.ws_order_number
LEFT JOIN 
    total_sales AS ts ON rs.ws_order_number = ts.ws_order_number
LEFT JOIN 
    item_details AS id ON rs.ws_item_sk = id.i_item_sk
LEFT JOIN 
    store_sales AS ss ON cust.c_customer_sk = ss.ss_customer_sk
WHERE 
    (cust.c_birth_year > 1980 OR NULLIF(cust.c_birth_country, '') IS NULL)
    AND COALESCE(ts.total_sales_price, 0) > (SELECT AVG(total_sales_price) FROM total_sales)
GROUP BY 
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    ts.total_sales_price,
    id.i_item_desc,
    id.current_price,
    rs.rn
HAVING 
    COUNT(DISTINCT ss.ss_ticket_number) > 0
ORDER BY 
    total_spent DESC
LIMIT 10;
