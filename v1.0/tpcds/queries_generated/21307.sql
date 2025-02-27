
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
avg_spend AS (
    SELECT 
        AVG(total_spent) AS average_spent
    FROM 
        ranked_sales
),
customer_categories AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN r.total_orders IS NULL THEN 'No Purchases'
            WHEN r.total_orders < 5 THEN 'Occasional Buyer'
            WHEN r.total_orders BETWEEN 5 AND 15 THEN 'Frequent Buyer'
            ELSE 'VIP Buyer'
        END AS customer_category
    FROM 
        ranked_sales r
    RIGHT JOIN 
        customer c ON r.c_customer_id = c.c_customer_id
),
excluded_customers AS (
    SELECT 
        c.c_customer_id
    FROM 
        customer c 
    LEFT JOIN 
        customer_categories cc ON c.c_customer_id = cc.c_customer_id
    WHERE 
        cc.customer_category IS NULL OR cc.customer_category = 'No Purchases'
),
final_summary AS (
    SELECT 
        cc.customer_category,
        COUNT(cc.customer_category) AS customer_count,
        SUM(COALESCE(r.total_spent, 0)) AS total_revenue,
        AVG(COALESCE(r.total_spent, 0)) AS avg_spent_per_customer
    FROM 
        customer_categories cc
    LEFT JOIN 
        ranked_sales r ON cc.c_customer_id = r.c_customer_id
    WHERE 
        cc.c_customer_id NOT IN (SELECT c.c_customer_id FROM excluded_customers)
    GROUP BY 
        cc.customer_category
)

SELECT 
    fs.customer_category,
    fs.customer_count,
    fs.total_revenue,
    fs.avg_spent_per_customer,
    (fs.total_revenue - (SELECT COALESCE(SUM(ws.net_profit), 0) FROM web_sales ws INNER JOIN store s ON ws.ws_store_sk = s.s_store_sk WHERE s.s_city = 'New York')) AS adjusted_revenue
FROM 
    final_summary fs
WHERE 
    fs.customer_count > (SELECT AVG(customer_count) FROM final_summary) OR 
    EXISTS (SELECT 1 FROM avg_spend a WHERE fs.avg_spent_per_customer < a.average_spent)
ORDER BY 
    fs.customer_category;
