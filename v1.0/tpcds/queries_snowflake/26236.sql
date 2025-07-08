
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        LISTAGG(DISTINCT ca_city || ', ' || ca_street_name || ' ' || ca_street_number, '; ') AS address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        'Web' AS sale_channel,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY sale_channel
    UNION ALL
    SELECT 
        'Store' AS sale_channel,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_orders
    FROM 
        store_sales
    GROUP BY sale_channel
),
CombinedReport AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.unique_cities,
        a.address_list,
        c.cd_gender,
        c.total_customers,
        c.avg_purchase_estimate,
        s.sale_channel,
        s.total_sales,
        s.total_orders
    FROM 
        AddressSummary a
    JOIN 
        CustomerDemographics c ON a.unique_addresses > 0
    JOIN 
        SalesSummary s ON s.total_sales > 0
)
SELECT 
    ca_state,
    unique_addresses,
    unique_cities,
    address_list,
    cd_gender,
    total_customers,
    avg_purchase_estimate,
    sale_channel,
    total_sales,
    total_orders
FROM 
    CombinedReport
ORDER BY 
    ca_state, cd_gender;
