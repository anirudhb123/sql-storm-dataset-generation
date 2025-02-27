
WITH CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        dc.cd_gender,
        dc.cd_marital_status,
        dc.cd_education_status,
        dc.cd_purchase_estimate,
        dc.cd_credit_rating,
        dc.cd_dep_count,
        dc.cd_dep_employed_count,
        dc.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_sales,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_sales
    FROM customer c
    JOIN customer_demographics dc ON c.c_current_cdemo_sk = dc.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DemographicsAggregated AS (
    SELECT 
        ca.ca_state,
        COUNT(*) AS customers_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate,
        COUNT(DISTINCT cd_gender) AS gender_variation,
        SUM(total_store_sales) AS total_store_sales,
        SUM(total_web_sales) AS total_web_sales
    FROM CustomerStatistics
    GROUP BY ca.ca_state
)
SELECT 
    da.ca_state,
    da.customers_count,
    da.average_purchase_estimate,
    da.gender_variation,
    da.total_store_sales,
    da.total_web_sales,
    CASE 
        WHEN da.average_purchase_estimate > 10000 THEN 'High Value'
        WHEN da.average_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS Value_Category
FROM DemographicsAggregated da
ORDER BY da.total_store_sales DESC, da.average_purchase_estimate DESC;
