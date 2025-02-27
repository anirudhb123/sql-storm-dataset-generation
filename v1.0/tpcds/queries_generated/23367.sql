
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity_sold
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 
        AND ws_ext_sales_price IS NOT NULL
),
high_value_items AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        ranked_sales 
    JOIN 
        item ON ranked_sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales_rank = 1
    GROUP BY 
        item.i_item_id, item.i_product_name
),
customer_activity AS (
    SELECT 
        c.c_customer_id, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
promotional_items AS (
    SELECT 
        p.p_promo_id, 
        COUNT(DISTINCT ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers, 
    SUM(hvi.total_sales) AS high_value_item_sales,
    COALESCE(SUM(promo.promo_order_count), 0) AS total_promo_orders,
    COUNT(DISTINCT CASE WHEN total_quantity_sold > 10 THEN ws_item_sk END) AS high_quantity_items
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    high_value_items hvi ON hvi.total_sales > 1000
LEFT JOIN 
    customer_activity ca_agg ON c.c_customer_id = ca_agg.c_customer_id
LEFT JOIN 
    promotional_items promo ON promo.promo_order_count > 0
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY 
    unique_customers DESC, 
    high_value_item_sales DESC
LIMIT 10 OFFSET 5;
