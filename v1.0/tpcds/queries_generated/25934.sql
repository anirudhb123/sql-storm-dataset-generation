
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(ca_address_sk) AS address_count, 
        STRING_AGG(ca_city, ', ') AS cities_list,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesStats AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
),
CombinedStats AS (
    SELECT 
        as.ca_state,
        as.address_count,
        as.cities_list,
        as.min_zip,
        as.max_zip,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        AddressStats as
    LEFT JOIN 
        SalesStats ss ON as.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = ss.ws_bill_addr_sk LIMIT 1)
)

SELECT 
    ca_state, 
    address_count, 
    cities_list, 
    min_zip, 
    max_zip, 
    total_sales, 
    total_orders, 
    CASE 
        WHEN total_orders > 0 THEN total_sales / total_orders 
        ELSE 0 
    END AS avg_sales_per_order
FROM 
    CombinedStats
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
