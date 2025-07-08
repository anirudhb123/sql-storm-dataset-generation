
WITH AddressSummary AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count, 
        LISTAGG(DISTINCT ca_street_name, ', ') AS unique_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS customer_count, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_ship_date_sk, 
        SUM(ws_net_paid) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
CombinedSummary AS (
    SELECT 
        ASUM.ca_city, 
        ASUM.ca_state, 
        ASUM.address_count, 
        ASUM.unique_streets, 
        DSUM.cd_gender, 
        DSUM.customer_count, 
        DSUM.avg_purchase_estimate, 
        SSUM.ws_ship_date_sk, 
        SSUM.total_sales, 
        SSUM.order_count
    FROM 
        AddressSummary AS ASUM
    JOIN 
        DemographicSummary AS DSUM ON ASUM.ca_state = 'NY' 
    JOIN 
        SalesSummary AS SSUM ON SSUM.ws_ship_date_sk BETWEEN 20230101 AND 20231231 
)
SELECT 
    ca_city, 
    ca_state, 
    address_count, 
    unique_streets, 
    cd_gender, 
    customer_count, 
    avg_purchase_estimate, 
    ws_ship_date_sk, 
    total_sales, 
    order_count
FROM 
    CombinedSummary
ORDER BY 
    total_sales DESC, 
    customer_count DESC;
