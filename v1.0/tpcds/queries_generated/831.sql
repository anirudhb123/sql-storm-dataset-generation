
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(ws.ws_item_sk) AS items_ordered
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        c.c_customer_sk, c.c_gender
),
customer_ranking AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_gender,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (PARTITION BY cs.c_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
),
top_customers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_gender,
        cr.total_sales,
        cr.order_count
    FROM 
        customer_ranking cr
    WHERE 
        cr.sales_rank <= 10
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT tc.c_customer_sk) AS top_customer_count,
    AVG(tc.total_sales) AS avg_sales_per_top_customer,
    MIN(tc.total_sales) AS min_sales,
    MAX(tc.total_sales) AS max_sales
FROM 
    customer_address ca
LEFT JOIN 
    top_customers tc ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
GROUP BY 
    ca.ca_city
ORDER BY 
    top_customer_count DESC, avg_sales_per_top_customer DESC;
