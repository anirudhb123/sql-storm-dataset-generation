
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ac.ca_city,
    ac.address_count,
    ac.street_names,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.avg_purchase_estimate,
    cs.education_levels,
    ss.total_sales,
    ss.order_count
FROM 
    AddressCounts ac
JOIN 
    CustomerStats cs ON cs.avg_purchase_estimate > 500
JOIN 
    SalesSummary ss ON ss.ws_bill_customer_sk IN (
        SELECT c_customer_sk FROM customer WHERE c_first_name LIKE '%John%'
    )
ORDER BY 
    ac.address_count DESC, 
    ss.total_sales DESC;
