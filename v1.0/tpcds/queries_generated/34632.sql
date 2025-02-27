
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_sales_price,
        s.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_sales_price,
        s.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN 
        sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    WHERE 
        sh.purchase_rank < 5
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        SUM(s.ss_net_profit) AS total_profit,
        COUNT(s.ss_item_sk) AS total_items_sold
    FROM 
        sales_hierarchy s
    JOIN 
        customer c ON s.c_customer_sk = c.c_customer_sk
    WHERE 
        s.purchase_rank = 1
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        full_name,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
    FROM 
        customer_sales
)
SELECT 
    tc.full_name,
    tc.total_profit,
    COALESCE(a.ca_city, 'N/A') AS city,
    COUNT(DISTINCT sa.ss_item_sk) AS unique_items_sold,
    CASE 
        WHEN tc.total_profit > 1000 THEN 'High'
        WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS customer_value_segment
FROM 
    top_customers tc 
LEFT JOIN 
    customer_address a ON a.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
LEFT JOIN 
    store_sales sa ON sa.ss_ticket_number = (SELECT s.ss_ticket_number FROM store_sales s WHERE s.ss_customer_sk = tc.c_customer_sk LIMIT 1)
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.full_name, tc.total_profit, a.ca_city
ORDER BY 
    tc.total_profit DESC;
