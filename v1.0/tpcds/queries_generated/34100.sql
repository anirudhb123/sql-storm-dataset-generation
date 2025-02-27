
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
), 
customer_return AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(cr.returning_customer_sk) AS returns_count,
        SUM(cr.return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
), 
address_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT s.ss_ticket_number) AS store_sales_count,
        SUM(s.ss_net_paid_inc_tax) AS store_total_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city, ca.ca_state
)
SELECT 
    a.c_customer_sk,
    a.ca_city,
    a.ca_state,
    COALESCE(sr.rank, 0) AS sales_rank,
    COALESCE(cr.returns_count, 0) AS returns_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(sr.total_sales, 0) > 5000 THEN 'High Value'
        WHEN COALESCE(sr.total_sales, 0) BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    address_info a
LEFT JOIN 
    sales_rank sr ON a.c_customer_sk = sr.web_site_sk
LEFT JOIN 
    customer_return cr ON a.c_customer_sk = cr.returning_customer_sk
WHERE 
    (a.store_sales_count > 0 OR cr.returns_count > 0)
    AND a.ca_state IS NOT NULL
ORDER BY 
    total_return_amount DESC, sales_rank;
