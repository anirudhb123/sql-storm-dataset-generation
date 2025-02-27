
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_streets
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerGender AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStatistics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.cities,
        a.unique_streets,
        c.cd_gender,
        c.customer_count,
        s.total_quantity,
        s.total_sales
    FROM 
        AddressStats a
    JOIN 
        CustomerGender c ON 1=1
    LEFT JOIN 
        SalesStatistics s ON c.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = s.ws_bill_customer_sk))
)
SELECT 
    fa.ca_state,
    fa.address_count,
    fa.cities,
    fa.unique_streets,
    fa.cd_gender,
    fa.customer_count,
    COALESCE(fa.total_quantity, 0) AS total_quantity,
    COALESCE(fa.total_sales, 0) AS total_sales
FROM 
    FinalBenchmark fa
ORDER BY 
    fa.ca_state, fa.cd_gender;
