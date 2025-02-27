
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
), SalesRanked AS (
    SELECT 
        customer_id,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
), HighValueCustomers AS (
    SELECT 
        cr.customer_id,
        cr.total_sales,
        cr.order_count,
        CASE 
            WHEN cr.total_sales > 1000 THEN 'Very High Value'
            WHEN cr.total_sales BETWEEN 500 AND 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_value_category
    FROM 
        SalesRanked cr
    WHERE 
        cr.sales_rank <= 100
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    a.ca_state,
    hv.customer_value_category,
    hv.total_sales,
    hv.order_count
FROM 
    high_value_customers hv
JOIN 
    customer c ON hv.customer_id = c.c_customer_id
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    (hv.total_sales IS NOT NULL AND hv.total_sales > 500)
    OR (hv.order_count IS NOT NULL AND hv.order_count > 5)
ORDER BY 
    hv.total_sales DESC, c.c_last_name ASC;
