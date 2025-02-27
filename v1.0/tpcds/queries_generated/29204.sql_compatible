
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
WebSalesStats AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),
FinalStats AS (
    SELECT 
        as.ca_state,
        as.address_count,
        as.max_street_name_length,
        as.avg_street_name_length,
        cs.avg_purchase_estimate,
        cs.customer_count,
        w.total_sales,
        w.total_orders
    FROM 
        AddressStats as
    LEFT JOIN 
        CustomerStats cs ON 1=1
    LEFT JOIN 
        WebSalesStats w ON 1=1
)
SELECT 
    fs.ca_state,
    fs.address_count,
    fs.max_street_name_length,
    fs.avg_street_name_length,
    fs.avg_purchase_estimate,
    fs.customer_count,
    fs.total_sales,
    fs.total_orders
FROM 
    FinalStats fs
ORDER BY 
    fs.address_count DESC, fs.total_sales DESC;
