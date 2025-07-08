
WITH InterestingAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        CONCAT(ca_street_name, ' ', ca_street_type) AS full_street_name,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_city LIKE '%town%' 
        AND ca_state IN ('CA', 'NY')
),
CustomerStats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender
),
SalesStats AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    ia.ca_address_sk,
    ia.full_street_name,
    ia.ca_city,
    ia.ca_state,
    ia.ca_zip,
    cs.cd_gender,
    cs.customer_count,
    cs.total_dependents,
    cs.avg_purchase_estimate,
    ss.total_sales,
    ss.total_orders
FROM 
    InterestingAddresses ia
LEFT JOIN 
    CustomerStats cs ON cs.cd_demo_sk IN (
        SELECT cd_demo_sk 
        FROM customer WHERE c_current_addr_sk = ia.ca_address_sk
    )
LEFT JOIN 
    SalesStats ss ON ss.ws_bill_addr_sk = ia.ca_address_sk
WHERE 
    ss.total_sales > 10000 OR ss.total_sales IS NULL
ORDER BY 
    ia.ca_city, cs.cd_gender;
