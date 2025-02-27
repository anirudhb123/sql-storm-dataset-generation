
WITH AddressCounts AS (
    SELECT 
        ca_country,
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_country
),
Demographics AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN ws_quantity > 0 THEN 'Positive Sales'
            ELSE 'No Sales'
        END AS sales_status,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        CASE 
            WHEN ws_quantity > 0 THEN 'Positive Sales'
            ELSE 'No Sales'
        END
)
SELECT 
    a.ca_country,
    a.address_count,
    a.cities,
    d.cd_gender,
    d.avg_purchase_estimate,
    s.sales_status,
    s.total_orders,
    s.total_sales
FROM 
    AddressCounts a
JOIN 
    Demographics d ON a.address_count > 100
JOIN 
    SalesSummary s ON s.total_sales > 10000
ORDER BY 
    a.ca_country, d.cd_gender, s.total_sales DESC;
