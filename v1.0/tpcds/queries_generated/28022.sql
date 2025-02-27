
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
),
CitySummary AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT f.full_name, ', ') AS top_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        FilteredCustomers f ON c.c_customer_id = f.c_customer_id
    GROUP BY 
        ca.ca_city
)
SELECT 
    ca.ca_city,
    cs.customer_count,
    cs.top_customers,
    COUNT(DISTINCT w.w_warehouse_id) AS total_warehouses,
    COUNT(DISTINCT s.s_store_id) AS total_stores
FROM 
    CitySummary cs
JOIN 
    customer_address ca ON cs.customer_count > 0
JOIN 
    warehouse w ON TRUE
JOIN 
    store s ON TRUE
GROUP BY 
    ca.ca_city, cs.customer_count, cs.top_customers
ORDER BY 
    customer_count DESC;
