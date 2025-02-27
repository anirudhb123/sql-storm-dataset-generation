
WITH Address_Processing AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        SUBSTRING_INDEX(ca_city, ' ', 1) AS city_prefix,
        ca_state,
        LENGTH(ca_zip) AS zip_length
    FROM customer_address
),
Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        UPPER(cd_marital_status) AS marital_status,
        TRIM(cd_education_status) AS education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(cd_gender, ':', cd_marital_status) AS gender_marital
    FROM customer_demographics
),
Date_Dimension AS (
    SELECT 
        d_date_sk,
        DATE_FORMAT(d_date, '%Y-%m-%d') AS formatted_date,
        d_year,
        d_month_seq,
        d_week_seq,
        d_day_name,
        d_current_month
    FROM date_dim
),
Web_Sales_Aggregation AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)

SELECT 
    ca.full_address,
    cd.gender_marital,
    dd.formatted_date,
    ws.total_sales,
    ws.order_count,
    COUNT(1) OVER (PARTITION BY dd.d_year ORDER BY NULL) AS yearly_customer_count,
    SUM(ws.total_sales) OVER () AS grand_total_sales
FROM Address_Processing ca
JOIN Customer_Demographics cd ON ca.ca_address_sk = cd.cd_demo_sk
JOIN Date_Dimension dd ON dd.d_date_sk = ca.ca_address_sk  -- Assuming overlap for demo
JOIN Web_Sales_Aggregation ws ON ws.ws_bill_customer_sk = cd.cd_demo_sk
WHERE ca.zip_length IN (5, 9)
  AND dd.d_current_month = 'Y'
ORDER BY dd.formatted_date DESC;
