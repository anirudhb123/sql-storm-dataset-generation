
WITH AddressData AS (
    SELECT 
        ca.city AS city,
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS full_address,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city, ca.street_number, ca.street_name, ca.street_type
),
SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
DemographicsData AS (
    SELECT 
        cd.cd_gender,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender
)
SELECT 
    a.city,
    a.full_address,
    a.customer_count,
    s.total_quantity_sold,
    s.total_sales_value,
    d.cd_gender,
    d.total_dependents,
    d.avg_purchase_estimate
FROM 
    AddressData a
LEFT JOIN 
    SalesData s ON a.city = (SELECT city FROM customer_address WHERE ca_address_sk = a.city)  -- Simplified for demo purposes
LEFT JOIN 
    DemographicsData d ON d.cd_gender IN ('M', 'F')  -- Filtering for both genders
ORDER BY 
    a.customer_count DESC, s.total_sales_value DESC
LIMIT 100;
