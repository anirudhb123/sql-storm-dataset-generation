
WITH AddressSummary AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count, 
        STRING_AGG(ca_city, ', ') AS cities, 
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number, '; ') AS street_info
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 0
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        'web' AS sale_type,
        ws_bill_cdemo_sk AS demo_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk

    UNION ALL

    SELECT 
        'store' AS sale_type, 
        ss_cdemo_sk AS demo_sk,
        SUM(ss_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_cdemo_sk
),
CombinedSummary AS (
    SELECT 
        s.sale_type, 
        d.cd_gender, 
        d.cd_marital_status, 
        SUM(s.total_sales) AS total_sales
    FROM 
        SalesSummary s
    LEFT JOIN 
        CustomerDemographics d ON s.demo_sk = d.cd_demo_sk
    GROUP BY 
        s.sale_type, d.cd_gender, d.cd_marital_status
)
SELECT 
    a.ca_state, 
    a.address_count, 
    a.cities, 
    a.street_info, 
    c.total_sales AS total_sales_web,
    COALESCE(s.total_sales, 0) AS total_sales_store
FROM 
    AddressSummary a
LEFT JOIN 
    CombinedSummary c ON a.address_count > 100
LEFT JOIN 
    (SELECT SUM(total_sales) AS total_sales FROM SalesSummary WHERE sale_type = 'store') s ON a.address_count <= 100
ORDER BY 
    a.ca_state;
