
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        COALESCE(c.c_first_name, 'Unknown') AS customer_first_name,
        COALESCE(c.c_last_name, 'Unknown') AS customer_last_name
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000 -- Arbitrary date range
),
top_sales AS (
    SELECT 
        r.bill_customer_sk,
        r.item_sk,
        r.ws_sales_price,
        r.customer_first_name,
        r.customer_last_name
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 5
),
sales_summary AS (
    SELECT 
        t.bill_customer_sk,
        COUNT(*) AS total_purchases,
        SUM(t.ws_sales_price) AS total_spent
    FROM 
        top_sales t
    GROUP BY 
        t.bill_customer_sk
)
SELECT 
    s.customer_first_name,
    s.customer_last_name,
    s.total_purchases,
    s.total_spent,
    CASE 
        WHEN s.total_spent IS NULL THEN 'No Purchases'
        ELSE CONCAT('Spent: $', ROUND(s.total_spent, 2))
    END AS spending_summary,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.bill_customer_sk = s.bill_customer_sk) AS total_orders_from_web_sales,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.bill_customer_sk = s.bill_customer_sk) AS total_orders_from_catalog_sales
FROM 
    sales_summary s
LEFT JOIN 
    customer c ON s.bill_customer_sk = c.c_customer_sk
JOIN 
    store_sales ss ON ss.ss_customer_sk = s.bill_customer_sk
WHERE 
    s.total_spent > 100
ORDER BY 
    s.total_spent DESC
LIMIT 10;
