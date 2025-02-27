
WITH AddressAggregate AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_city,
        ca_state
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        da.ca_city,
        da.ca_state,
        da.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address da ON c.c_current_addr_sk = da.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    aa.unique_addresses,
    aa.avg_gmt_offset,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_orders, 0) AS total_orders
FROM 
    CustomerDetails cd
LEFT JOIN 
    AddressAggregate aa ON cd.ca_city = aa.ca_city AND cd.ca_state = aa.ca_state
LEFT JOIN 
    SalesInfo si ON cd.c_customer_id = si.ws_bill_customer_sk
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC, cd.full_name;
