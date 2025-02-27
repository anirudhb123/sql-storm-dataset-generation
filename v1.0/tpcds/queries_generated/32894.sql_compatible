
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS average_purchase,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
AddressAnalysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customers_count,
        MAX(ca_gmt_offset) AS max_gmt_offset
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    a.ca_state,
    a.customers_count,
    a.max_gmt_offset,
    COALESCE(s.total_sales, 0) AS total_sales,
    s.order_count,
    d.average_purchase,
    d.total_dependents
FROM 
    DemographicAnalysis d
FULL OUTER JOIN 
    AddressAnalysis a ON d.cd_gender IN ('M', 'F') OR d.cd_marital_status IS NULL
LEFT JOIN 
    SalesCTE s ON d.cd_gender = (SELECT DISTINCT cd_gender FROM customer_demographics WHERE cd_demo_sk = s.ws_bill_customer_sk)
WHERE 
    (d.average_purchase > 1000 OR a.customers_count < 50)
    AND (a.max_gmt_offset IS NOT NULL OR d.cd_marital_status IS NOT NULL)
ORDER BY 
    a.customers_count DESC, 
    s.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
