
WITH RECURSIVE SalesHistory AS (
    SELECT 
        ss_sold_date_sk AS sale_date,
        ss_store_sk AS store_id,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_store_sk
    HAVING 
        SUM(ss_sales_price) > 0
),
AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA' OR ca_state IS NULL
)
SELECT 
    s.sale_date,
    s.store_id,
    s.total_sales,
    a.full_address,
    a.ca_city,
    a.ca_state,
    DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS overall_rank,
    (SELECT COUNT(DISTINCT c.c_customer_sk) 
     FROM customer c 
     WHERE c.c_current_addr_sk = a.ca_address_sk) AS customer_count
FROM 
    SalesHistory s
LEFT JOIN 
    AddressDetails a ON s.store_id = a.ca_address_sk
WHERE 
    s.sales_rank <= 10 
    AND (a.ca_city LIKE '%Los Angeles%' OR a.ca_city IS NULL)
ORDER BY 
    s.total_sales DESC
LIMIT 100
UNION ALL
SELECT 
    'Total' AS sale_date,
    NULL AS store_id,
    SUM(total_sales) AS total_sales,
    NULL AS full_address,
    NULL AS ca_city,
    NULL AS ca_state,
    NULL AS overall_rank,
    NULL AS customer_count
FROM 
    SalesHistory;
