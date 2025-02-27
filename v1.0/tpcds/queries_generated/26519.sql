
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS city_upper,
        ca_state,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ss.s_store_sk, 
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transactions
    FROM 
        store_sales ss
    GROUP BY 
        ss.s_store_sk
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ai.full_address,
    ai.city_upper,
    ai.ca_state,
    ai.zip_prefix,
    si.total_sales,
    si.transactions,
    wi.total_items
FROM 
    CustomerInfo ci
JOIN 
    customer_address ca ON ci.c_customer_sk = ca.ca_address_sk 
JOIN 
    AddressInfo ai ON ai.ca_address_sk = ca.ca_address_sk 
JOIN 
    SalesInfo si ON si.s_store_sk = ca.ca_address_sk 
JOIN 
    WarehouseInfo wi ON wi.w_warehouse_sk = ca.ca_address_sk 
WHERE 
    ci.cd_gender = 'F' 
    AND si.total_sales > 1000 
    AND ai.zip_prefix BETWEEN '10000' AND '20000'
ORDER BY 
    total_sales DESC;
