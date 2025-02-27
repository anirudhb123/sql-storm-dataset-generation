
WITH AddressProcessing AS (
    SELECT 
        ca_address_id,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicsProcessing AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT(TRIM('Gender: ', cd_gender), ' | ', TRIM('Marital Status: ', cd_marital_status), ' | ', 
               TRIM('Education: ', cd_education_status)) AS demographic_info
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
DetailedSales AS (
    SELECT 
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        s.ss_ticket_number,
        CONCAT('Item SK: ', ss.ss_item_sk, ' | Total Sales: ', ROUND(ss.ss_net_paid_inc_tax, 2), 
               ' | Quantity Sold: ', ss.ss_quantity) AS sales_info
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
)
SELECT 
    a.ca_address_id,
    a.full_address,
    d.demographic_info,
    s.total_sales,
    s.total_orders,
    ds.warehouse_name,
    ds.sales_info
FROM 
    AddressProcessing a
JOIN 
    DemographicsProcessing d ON a.ca_address_id = d.cd_demo_sk
JOIN 
    SalesData s ON d.cd_demo_sk = s.ws_item_sk
JOIN 
    DetailedSales ds ON ds.ss_ticket_number = s.total_orders
WHERE 
    a.ca_state = 'CA' 
ORDER BY 
    total_sales DESC, 
    a.ca_city, 
    d.cd_purchase_estimate;
