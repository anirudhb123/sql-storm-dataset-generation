
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS city_list,
        STRING_AGG(DISTINCT ca_street_name, '; ') AS unique_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesMetrics AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ac.ca_state,
    ac.address_count,
    ac.city_list,
    ac.unique_street_names,
    d.cd_gender,
    d.cd_marital_status,
    d.total_dependents,
    d.customer_count,
    sm.total_sales,
    sm.average_sales_price,
    sm.total_orders
FROM 
    AddressCounts ac
JOIN 
    Demographics d ON d.customer_count > 100
LEFT JOIN 
    SalesMetrics sm ON sm.ws_bill_cdemo_sk IN (SELECT cd_demo_sk FROM customer)
WHERE 
    ac.address_count > 500
ORDER BY 
    ac.ca_state, d.cd_gender, sm.total_sales DESC;
