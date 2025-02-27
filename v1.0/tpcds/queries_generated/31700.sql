
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        NULL AS parent_customer
    FROM 
        customer c
    WHERE 
        c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.c_customer_sk AS parent_customer
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_cdemo_sk
)

, AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)

SELECT 
    d.d_date AS sales_date,
    w.w_warehouse_name,
    SUM(COALESCE(ss.ss_net_paid, 0)) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS transactions,
    Ad.ca_city,
    Ad.ca_state,
    COUNT(DISTINCT CH.c_customer_sk) AS unique_customers
FROM 
    date_dim d
LEFT JOIN 
    store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
LEFT JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN 
    warehouse w ON s.s_company_id = w.w_warehouse_sk
LEFT JOIN 
    AddressDetails Ad ON s.s_store_sk = Ad.ca_address_sk
LEFT JOIN 
    CustomerHierarchy CH ON CH.c_customer_sk = ss.ss_customer_sk
WHERE 
    d.d_year = 2023 
    AND (Ad.customer_count IS NULL OR Ad.customer_count >= 10)
GROUP BY 
    d.d_date, w.w_warehouse_name, Ad.ca_city, Ad.ca_state
ORDER BY 
    d.d_date DESC, total_sales DESC
LIMIT 100;
