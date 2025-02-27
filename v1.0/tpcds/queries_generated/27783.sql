
WITH address_summary AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_street_name) AS unique_street_names,
        COUNT(DISTINCT ca_street_type) AS unique_street_types,
        MAX(ca_gmt_offset) AS max_gmt_offset,
        MIN(ca_gmt_offset) AS min_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
demographics_summary AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS unique_demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        SUM(ws_sales_price) AS total_web_sales,
        SUM(cs_sales_price) AS total_catalog_sales,
        SUM(ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss_ticket_number) AS total_store_tickets
    FROM 
        web_sales
    JOIN 
        catalog_sales ON ws_item_sk = cs_item_sk
    JOIN 
        store_sales ON ws_item_sk = ss_item_sk
),
final_summary AS (
    SELECT 
        a.ca_city,
        a.unique_addresses,
        a.unique_street_names,
        a.unique_street_types,
        a.max_gmt_offset,
        a.min_gmt_offset,
        d.cd_gender,
        d.avg_purchase_estimate,
        d.unique_demographics,
        s.total_web_sales,
        s.total_catalog_sales,
        s.total_store_sales,
        s.total_web_orders,
        s.total_catalog_orders,
        s.total_store_tickets
    FROM 
        address_summary a
    JOIN 
        demographics_summary d ON a.unique_addresses > 0
    JOIN 
        sales_summary s ON s.total_web_orders > 0
)
SELECT 
    CONCAT('City: ', ca_city, ', Unique Addresses: ', unique_addresses, ', Unique Street Names: ', unique_street_names, 
           ', Unique Street Types: ', unique_street_types, ', Max GMT Offset: ', max_gmt_offset, 
           ', Min GMT Offset: ', min_gmt_offset, ', Gender: ', cd_gender, 
           ', Avg Purchase Estimate: ', avg_purchase_estimate, 
           ', Unique Demographics: ', unique_demographics, 
           ', Total Web Sales: ', total_web_sales, 
           ', Total Catalog Sales: ', total_catalog_sales, 
           ', Total Store Sales: ', total_store_sales, 
           ', Total Web Orders: ', total_web_orders, 
           ', Total Catalog Orders: ', total_catalog_orders, 
           ', Total Store Tickets: ', total_store_tickets) AS benchmark_summary
FROM 
    final_summary
ORDER BY 
    unique_addresses DESC, avg_purchase_estimate DESC;
