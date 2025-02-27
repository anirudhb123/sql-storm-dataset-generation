
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_address
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(CASE WHEN ws_ship_date_sk IS NOT NULL THEN ws_quantity ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs_ship_date_sk IS NOT NULL THEN cs_quantity ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss_sold_date_sk IS NOT NULL THEN ss_quantity ELSE 0 END) AS total_store_sales
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN 
        catalog_sales cs ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.warehouse_name
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.full_address,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    s.w_warehouse_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales
FROM 
    AddressInfo a
JOIN 
    CustomerInfo c ON a.ca_city = c.cd_gender
JOIN 
    SalesSummary s ON LOWER(a.ca_state) = LOWER(s.w_warehouse_name)
ORDER BY 
    a.ca_city, c.customer_count DESC, s.total_web_sales DESC;
