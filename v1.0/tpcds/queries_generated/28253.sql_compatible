
WITH CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        a.ca_city,
        a.ca_state,
        SUBSTRING(a.ca_street_name FROM '[^ ]+$') AS Street_Tail,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS Full_Name,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS Name_Length,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS Gender_Description
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE 
        LENGTH(c.c_email_address) > 10
),
AggregatedStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS Customer_Count,
        AVG(cd_purchase_estimate) AS Avg_Purchase_Estimate,
        MAX(Name_Length) AS Max_Name_Length,
        MIN(Name_Length) AS Min_Name_Length
    FROM 
        CustomerStatistics
    GROUP BY 
        ca_state
)
SELECT 
    as.ca_state,
    as.Customer_Count,
    as.Avg_Purchase_Estimate,
    as.Max_Name_Length,
    as.Min_Name_Length,
    CASE 
        WHEN as.Avg_Purchase_Estimate > 500 THEN 'High Value'
        WHEN as.Avg_Purchase_Estimate BETWEEN 200 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Value_Category
FROM 
    AggregatedStatistics as
ORDER BY 
    as.Customer_Count DESC, 
    as.Avg_Purchase_Estimate DESC;
