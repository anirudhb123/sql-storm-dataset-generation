
WITH CustomerAddressCTE AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDemographicsCTE AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        UPPER(cd_purchase_estimate::TEXT) AS purchase_estimate_uppercased,
        INITCAP(cd_credit_rating) AS formatted_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
DateDimCTE AS (
    SELECT 
        d_date_id,
        TO_CHAR(d_date, 'Month YYYY') AS formatted_date,
        d_year,
        d_month_seq
    FROM 
        date_dim
),
WebSalesCTE AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ROUND(SUM(ws_sales_price), 2) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk, ws_quantity
)
SELECT 
    C.full_address,
    D.formatted_date,
    DEM.cd_gender,
    DEM.cd_marital_status,
    W.total_sales,
    W.order_count,
    CASE 
        WHEN W.total_sales > 500 THEN 'High Value'
        WHEN W.total_sales BETWEEN 200 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerAddressCTE AS C
JOIN 
    CustomerDemographicsCTE AS DEM ON C.ca_city = DEM.cd_gender  -- Assuming matching logic for the example
JOIN 
    DateDimCTE AS D ON D.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
JOIN 
    WebSalesCTE AS W ON W.ws_ship_date_sk = D.d_date_id
WHERE 
    C.ca_country = 'USA'
ORDER BY 
    W.total_sales DESC
LIMIT 100;
