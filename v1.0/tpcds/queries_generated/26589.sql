
WITH demographic_analysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c.c_customer_sk) AS total_customers,
        SUM(CASE WHEN c.c_birth_year BETWEEN 1980 AND 1990 THEN 1 ELSE 0 END) AS millennials_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
address_analysis AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_city, ', ') AS cities_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
sales_analysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        STRING_AGG(DISTINCT ws_item_sk::TEXT, ', ') AS sold_items
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.total_customers,
    da.millennials_count,
    da.avg_purchase_estimate,
    aa.ca_state,
    aa.total_addresses,
    aa.cities_list,
    sa.total_sales,
    sa.sold_items
FROM 
    demographic_analysis da
FULL OUTER JOIN 
    address_analysis aa ON da.cd_gender IS NOT NULL AND aa.total_addresses > 0
FULL OUTER JOIN 
    sales_analysis sa ON da.total_customers > 0 AND sa.ws_bill_customer_sk IS NOT NULL
ORDER BY 
    da.total_customers DESC, aa.total_addresses DESC;
