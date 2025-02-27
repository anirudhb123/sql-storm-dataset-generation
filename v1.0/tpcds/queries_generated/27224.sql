
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_city,
        ca_state
),
SalesData AS (
    SELECT 
        s_city,
        s_state,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s_city,
        s_state
),
CombinedData AS (
    SELECT 
        ai.ca_city,
        ai.ca_state,
        ai.customer_count,
        ai.customer_names,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_quantity, 0) AS total_quantity
    FROM 
        AddressInfo ai
    LEFT JOIN 
        SalesData sd ON ai.ca_city = sd.s_city AND ai.ca_state = sd.s_state
)
SELECT 
    ca_city, 
    ca_state, 
    customer_count, 
    customer_names, 
    total_sales, 
    total_quantity,
    CASE 
        WHEN total_sales = 0 THEN 'No sales'
        ELSE 'Sales recorded'
    END AS sales_status
FROM 
    CombinedData
ORDER BY 
    customer_count DESC, 
    total_sales DESC;
