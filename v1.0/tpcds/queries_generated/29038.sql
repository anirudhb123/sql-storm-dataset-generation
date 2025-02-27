
WITH CustomerLocation AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT C.c_customer_id) AS total_customers,
        SUM(CD.cd_dep_count) AS total_dependents,
        AVG(CD.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer C
    JOIN 
        customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
    JOIN 
        customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
    WHERE 
        C.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        ca_city, ca_state
),
SalesData AS (
    SELECT 
        SS.ss_store_sk,
        SUM(SS.ss_quantity) AS total_sales_quantity,
        SUM(SS.ss_net_paid) AS total_sales_amount
    FROM 
        store_sales SS
    JOIN 
        store S ON SS.ss_store_sk = S.s_store_sk
    WHERE 
        S.s_state IN (SELECT DISTINCT ca_state FROM customer_address)
    GROUP BY 
        SS.ss_store_sk
)
SELECT 
    CL.ca_city,
    CL.ca_state,
    CL.total_customers,
    CL.total_dependents,
    CL.avg_purchase_estimate,
    SD.total_sales_quantity,
    SD.total_sales_amount
FROM 
    CustomerLocation CL
LEFT JOIN 
    SalesData SD ON CL.ca_state = (SELECT DISTINCT ca_state FROM customer_address)
ORDER BY 
    CL.ca_state, CL.ca_city;
