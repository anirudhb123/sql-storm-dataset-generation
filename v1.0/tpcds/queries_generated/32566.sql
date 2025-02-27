
WITH RECURSIVE top_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    ORDER BY c_customer_sk
    LIMIT 10
), sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_net_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), address_summary AS (
    SELECT 
        ca_country, 
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address
    LEFT JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
    GROUP BY ca_country
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(ss.total_net_sales, 0) AS net_sales,
    COALESCE(ss.total_orders, 0) AS orders_count,
    asum.ca_country AS country,
    asum.customer_count
FROM 
    top_customers tc
LEFT JOIN 
    sales_summary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    address_summary asum ON tc.c_current_cdemo_sk = asum.ca_country
WHERE 
    (ss.total_net_sales > (SELECT AVG(total_net_sales) FROM sales_summary) 
        OR ss.total_orders > 5) 
    AND asum.customer_count IS NOT NULL
ORDER BY 
    net_sales DESC
LIMIT 20;
