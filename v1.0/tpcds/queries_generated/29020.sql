
WITH EnhancedAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
GenderIncome AS (
    SELECT 
        cd_gender,
        ib_upper_bound,
        ib_lower_bound,
        COUNT(cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
    JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY 
        cd_gender, ib_upper_bound, ib_lower_bound
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ea.full_address,
    gi.cd_gender,
    gi.ib_lower_bound,
    gi.ib_upper_bound,
    gi.demographic_count,
    gi.avg_purchase_estimate,
    sd.total_sales,
    sd.order_count
FROM 
    EnhancedAddress ea
JOIN 
    customer c ON ea.ca_address_sk = c.c_current_addr_sk
JOIN 
    GenderIncome gi ON c.c_current_cdemo_sk = gi.cd_demo_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ea.ca_state = 'CA'
ORDER BY 
    gi.avg_purchase_estimate DESC, 
    sd.total_sales DESC
LIMIT 100;
