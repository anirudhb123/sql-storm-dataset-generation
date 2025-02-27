
WITH RankedAddresses AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_street_name) AS addr_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
PopularWarehouses AS (
    SELECT 
        w_warehouse_id, 
        w_city, 
        COUNT(*) AS sales_count
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.warehouse_sk
    GROUP BY 
        w_warehouse_id, w_city
    HAVING 
        COUNT(*) > 100
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ca.full_address,
    cw.warehouse_name,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating
FROM 
    RankedAddresses ca
JOIN 
    PopularWarehouses cw ON ca.ca_city = cw.w_city
JOIN 
    CustomerInfo ci ON ci.cd_purchase_estimate > 5000
WHERE 
    ca.addr_rank <= 5
ORDER BY 
    ca.ca_city, cw.sales_count DESC, ci.cd_purchase_estimate DESC
LIMIT 100;
