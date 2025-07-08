
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        COUNT(*) AS address_count,
        LISTAGG(ca_street_name || ' ' || ca_street_type, ', ') AS street_info
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(*) AS demo_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS orders_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        a.ca_city,
        a.address_count,
        a.street_info,
        d.cd_gender,
        d.cd_marital_status,
        d.demo_count,
        s.total_sales,
        s.orders_count
    FROM 
        AddressCounts a
    JOIN 
        Demographics d ON d.demo_count > 50 
    LEFT JOIN 
        SalesSummary s ON s.ws_bill_customer_sk = a.address_count 
)
SELECT 
    ca_city,
    address_count,
    street_info,
    cd_gender,
    cd_marital_status,
    demo_count,
    total_sales,
    orders_count
FROM 
    FinalBenchmark
ORDER BY 
    total_sales DESC, 
    address_count DESC;
