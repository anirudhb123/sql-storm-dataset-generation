
WITH demographic_analysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.customer_count,
    da.avg_purchase_estimate,
    da.education_statuses,
    asu.address_count,
    asu.cities,
    ss.total_sales,
    ss.total_orders
FROM 
    demographic_analysis da
LEFT JOIN 
    address_summary asu ON da.cd_gender = 'M' AND da.customer_count > 100
LEFT JOIN 
    sales_summary ss ON ss.ws_bill_cdemo_sk = da.customer_count
ORDER BY 
    da.cd_gender, da.cd_marital_status;
