
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),
customer_with_address AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cwa.ca_city,
    cwa.ca_state,
    cwa.ca_zip,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    CASE 
        WHEN cs.sales_rank IS NULL THEN 'No Sales' 
        WHEN cs.total_web_sales > ss.total_store_sales THEN 'Web Sales Lead'
        ELSE 'Store Sales Lead'
    END AS sales_lead_status
FROM 
    customer_with_address cwa
LEFT JOIN 
    customer_sales cs ON cwa.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    store_sales_summary ss ON ss.ss_store_sk = cwa.c_customer_sk
WHERE 
    (cwa.ca_state = 'CA' OR cwa.ca_state = 'NY')
AND 
    COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) > 1000
ORDER BY 
    total_web_sales DESC, 
    total_store_sales DESC;
