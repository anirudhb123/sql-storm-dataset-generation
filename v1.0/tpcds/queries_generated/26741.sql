
WITH address_details AS (
    SELECT 
        ca_state, 
        ca_city, 
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state, 
        ca_city
),
demographic_details AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
sales_data AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
),
combined_data AS (
    SELECT 
        ad.ca_state, 
        ad.ca_city, 
        ad.address_count, 
        ad.street_names, 
        dd.cd_gender, 
        dd.cd_marital_status, 
        sd.total_sales, 
        sd.total_orders
    FROM 
        address_details ad
    JOIN 
        sales_data sd ON ad.ca_address_sk = sd.ws_bill_addr_sk
    JOIN 
        demographic_details dd ON sd.ws_bill_addr_sk = dd.cd_demo_sk
)
SELECT 
    ca_state, 
    ca_city, 
    address_count, 
    street_names, 
    cd_gender, 
    cd_marital_status, 
    total_sales, 
    total_orders
FROM 
    combined_data
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC, 
    address_count DESC;
