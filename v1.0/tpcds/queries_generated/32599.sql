
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(cs_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.total_quantity) AS total_sales_quantity,
    SUM(ss.total_net_paid) AS total_sales_amount,
    COALESCE(promo_order_count, 0) AS total_promo_orders
FROM 
    sales_summary ss
JOIN 
    web_sales ws ON ss.ws_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    promotions p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ss.total_quantity > (
        SELECT AVG(total_quantity) 
        FROM sales_summary 
        WHERE rnk = 1
    )
GROUP BY 
    c.c_customer_id, ca.ca_city, promo_order_count
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
