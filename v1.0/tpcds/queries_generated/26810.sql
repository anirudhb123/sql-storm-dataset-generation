
WITH CustomerAddress AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_city, ca_state
),
SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity
    FROM 
        store_sales s
    JOIN 
        warehouse w ON s.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
MergedData AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        cs.customer_count,
        sd.warehouse_name,
        sd.total_sales,
        sd.total_quantity
    FROM 
        CustomerAddress ca
    LEFT JOIN 
        SalesData sd ON ca.ca_city = sd.warehouse_name
    LEFT JOIN 
        (
            SELECT 
                ca_city, 
                ca_state, 
                SUM(total_sales) AS total_sales_by_city
            FROM 
                SalesData
            GROUP BY 
                ca_city, ca_state
        ) AS cs ON ca.ca_city = cs.ca_city AND ca.ca_state = cs.ca_state
)
SELECT 
    city,
    state,
    customer_count,
    warehouse_name,
    total_sales,
    total_quantity,
    total_sales * 100.0 / NULLIF(total_quantity, 0) AS avg_sales_price
FROM 
    MergedData
ORDER BY 
    total_sales DESC
LIMIT 10;
