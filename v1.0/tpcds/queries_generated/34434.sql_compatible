
WITH RECURSIVE sales_summary AS (
    SELECT 
        customer.c_customer_sk,
        COALESCE(SUM(ss_net_paid), 0) AS total_net_paid,
        COUNT(ss_ticket_number) AS total_transactions,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ss_net_paid), 0) DESC) AS sales_rank
    FROM 
        customer
    LEFT JOIN 
        store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
    GROUP BY 
        customer.c_customer_sk

    UNION ALL

    SELECT 
        customer.c_customer_sk,
        COALESCE(SUM(ws_net_paid), 0) AS total_net_paid,
        COUNT(ws_order_number) AS total_transactions,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ws_net_paid), 0) DESC) AS sales_rank
    FROM 
        customer
    LEFT JOIN 
        web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    GROUP BY 
        customer.c_customer_sk
),
top_customers AS (
    SELECT 
        sales_summary.c_customer_sk,
        sales_summary.total_net_paid,
        sales_summary.total_transactions,
        ROW_NUMBER() OVER (ORDER BY sales_summary.total_net_paid DESC) AS rank
    FROM 
        sales_summary
)
SELECT 
    ca.city,
    ca.state,
    COUNT(tc.c_customer_sk) AS number_of_customers,
    AVG(tc.total_net_paid) AS avg_net_paid,
    SUM(tc.total_transactions) AS total_transactions,
    STRING_AGG(DISTINCT c.c_email_address) AS email_list
FROM 
    top_customers tc
JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
WHERE 
    tc.rank <= 100 AND
    ca.state IS NOT NULL
GROUP BY 
    ca.city, ca.state
ORDER BY 
    number_of_customers DESC, avg_net_paid DESC
LIMIT 10;
