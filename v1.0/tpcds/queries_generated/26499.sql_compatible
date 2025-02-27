
WITH Address_Info AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY') AND ca_country = 'USA'
),
Customer_Demo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM customer_demographics
),
Return_Stats AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
Aggregated_Data AS (
    SELECT 
        d.d_date AS return_date,
        ai.full_address,
        cd.purchase_category,
        rs.total_returns,
        rs.total_return_amount,
        rs.total_return_tax
    FROM Return_Stats rs
    JOIN date_dim d ON rs.sr_returned_date_sk = d.d_date_sk
    JOIN Address_Info ai ON ai.ca_address_sk = rs.sr_addr_sk
    JOIN Customer_Demo cd ON cd.cd_demo_sk = rs.sr_cdemo_sk
)
SELECT 
    return_date,
    full_address,
    purchase_category,
    SUM(total_returns) AS aggregated_returns,
    SUM(total_return_amount) AS total_amount,
    SUM(total_return_tax) AS total_tax
FROM Aggregated_Data
GROUP BY 
    return_date, 
    full_address, 
    purchase_category
ORDER BY return_date DESC, aggregated_returns DESC;
