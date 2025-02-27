
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
nearby_stores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        k.a_address_street
    FROM 
        store s
    JOIN customer_address k ON s.s_store_sk = k.ca_address_sk
    WHERE 
        k.ca_state = 'CA' AND k.ca_zip LIKE '9%' 
    ORDER BY 
        s.s_store_name
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    ns.s_store_name,
    rs.ws_sales_price AS highest_price,
    AVG(NULLIF(rs.ws_sales_price, 0)) OVER () AS avg_highest_price,
    CASE 
        WHEN cs.total_orders > 10 THEN 'Gold'
        WHEN cs.total_orders BETWEEN 5 AND 10 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM 
    customer_sales cs
LEFT JOIN 
    ranked_sales rs ON cs.total_orders > 0 AND rs.rank = 1
LEFT JOIN 
    nearby_stores ns ON ns.s_store_sk = cs.c_customer_sk % 100  -- bizarre method to link customers to stores
WHERE 
    (cs.total_spent IS NOT NULL AND cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales WHERE total_orders > 0))
    OR (NULLIF(cs.total_spent, 0) IS NULL AND EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_returned_date_sk > 1000))
ORDER BY 
    cs.total_spent DESC, cs.c_last_name;
