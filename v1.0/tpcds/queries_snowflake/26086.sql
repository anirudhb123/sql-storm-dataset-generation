
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        SUM(length(ca_street_name) + length(ca_city) + length(ca_zip)) AS total_char_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    addr.ca_state,
    addr.address_count,
    addr.total_char_count,
    demo.cd_gender,
    demo.total_dependents,
    demo.avg_purchase_estimate,
    sale.total_sales,
    sale.order_count
FROM 
    AddressSummary addr
JOIN 
    DemographicSummary demo ON demo.total_dependents > 0 
JOIN 
    SalesSummary sale ON sale.ws_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = addr.ca_state)
ORDER BY 
    addr.ca_state, demo.cd_gender;
