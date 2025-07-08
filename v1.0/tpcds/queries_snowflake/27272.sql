
WITH CombinedData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city,
        ca.ca_state,
        COALESCE(COUNT(ws.ws_order_number), 0) AS total_orders,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
), FilteredData AS (
    SELECT 
        customer_name,
        ca_city,
        ca_state,
        total_orders,
        total_sales,
        LEN(customer_name) AS name_length,
        (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_demo_sk IN (
            SELECT DISTINCT c.c_current_cdemo_sk FROM customer c
            WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_city = CombinedData.ca_city)
        )) AS demographics_count
    FROM 
        CombinedData
    WHERE 
        total_sales > 1000
)
SELECT 
    customer_name,
    ca_city,
    ca_state,
    total_orders,
    total_sales,
    name_length,
    demographics_count
FROM 
    FilteredData
ORDER BY 
    total_sales DESC, name_length ASC 
LIMIT 100;
