
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date AS first_purchase_date,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
CustomerStats AS (
    SELECT
        ca_state,
        COUNT(*) AS total_customers,
        COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_count,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count,
        AVG(DATEDIFF(CURDATE(), first_purchase_date)) AS avg_days_since_first_purchase
    FROM 
        CustomerData
    GROUP BY 
        ca_state
) 
SELECT 
    cs.ca_state,
    cs.total_customers,
    cs.male_count,
    cs.female_count,
    cs.avg_days_since_first_purchase,
    CONCAT(cs.ca_state, ' - ', CAST(cs.total_customers AS CHAR), ' customers (', CAST(cs.male_count AS CHAR), ' males, ', CAST(cs.female_count AS CHAR), ' females)') AS summary
FROM 
    CustomerStats cs
WHERE 
    cs.total_customers > 100
ORDER BY 
    cs.total_customers DESC;
