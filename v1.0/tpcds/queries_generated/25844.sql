
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS unique_street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demo_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    addr.ca_city,
    addr.address_count,
    addr.avg_gmt_offset,
    addr.unique_street_types,
    demo.cd_gender,
    demo.demo_count,
    demo.total_dependents,
    demo.avg_purchase_estimate,
    sales.total_net_profit,
    sales.total_orders,
    sales.avg_sales_price
FROM 
    AddressStats addr
JOIN 
    Demographics demo ON addr.address_count > 100
JOIN 
    SalesData sales ON sales.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = (SELECT ca_address_sk FROM customer_address WHERE ca_city = addr.ca_city LIMIT 1))
WHERE 
    demo.avg_purchase_estimate > 500
ORDER BY 
    addr.address_count DESC, demo.demo_count DESC;
