
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredRankedCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, ' - ', cd_marital_status) AS gender_marital_status,
        rnk
    FROM 
        RankedCustomers
    WHERE 
        rnk <= 10
),
AggregatedData AS (
    SELECT 
        gender_marital_status,
        COUNT(*) AS customer_count,
        STRING_AGG(full_name, ', ') AS customer_names
    FROM 
        FilteredRankedCustomers
    GROUP BY 
        gender_marital_status
)
SELECT 
    gender_marital_status,
    customer_count,
    customer_names,
    UPPER(gender_marital_status) AS upper_gender_marital_status,
    LENGTH(customer_names) AS names_length,
    ARRAY_LENGTH(STRING_TO_ARRAY(customer_names, ', '), 1) AS names_array_length
FROM 
    AggregatedData
ORDER BY 
    customer_count DESC, upper_gender_marital_status;
