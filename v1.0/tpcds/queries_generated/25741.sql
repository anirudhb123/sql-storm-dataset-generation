
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_purchase_estimate > 10000 THEN 'High Value'
            WHEN cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS purchase_category
    FROM 
        customer_demographics
),
Sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        s.total_sales,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        Sales s ON i.i_item_sk = s.ws_item_sk
    WHERE 
        i.i_current_price > 0
)
SELECT 
    ad.full_address,
    d.cd_gender,
    d.purchase_category,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales,
    ti.total_orders
FROM 
    AddressDetails ad
JOIN 
    Demographics d ON d.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ad.ca_address_sk LIMIT 1)
JOIN 
    TopItems ti ON ti.total_sales > 1000
ORDER BY 
    ad.ca_city, 
    ti.total_sales DESC;
