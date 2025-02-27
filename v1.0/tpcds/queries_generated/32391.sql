
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_sales_price) > 0
),
customer_totals AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(ct.total_spent, 0) AS total_spent
    FROM 
        item i
    LEFT JOIN 
        (SELECT ws_item_sk, SUM(ws_ext_sales_price) AS total_sales 
         FROM web_sales 
         GROUP BY ws_item_sk) si ON i.i_item_sk = si.ws_item_sk
    LEFT JOIN 
        customer_totals ct ON ct.total_spent > 0
)
SELECT 
    id.i_item_desc,
    id.total_sales,
    id.total_spent,
    CASE 
        WHEN id.total_sales > 10000 THEN 'High Performer'
        WHEN id.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    item_details id
WHERE 
    id.total_spent > 0
ORDER BY 
    id.total_sales DESC;

-- Check for items with special promotions applied
SELECT 
    i.i_item_sk,
    p.p_promo_name,
    SUM(ws.ws_ext_sales_price) AS promotional_sales
FROM 
    web_sales ws
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    p.p_discount_active = 'Y'
GROUP BY 
    i.i_item_sk, p.p_promo_name
HAVING 
    SUM(ws.ws_ext_sales_price) > 5000;
