
WITH Address_Analysis AS (
    SELECT 
        ca_city,
        UPPER(ca_street_name) AS uppercase_street_name,
        LENGTH(ca_street_name) AS street_name_length,
        REPLACE(ca_street_name, 'St', 'Street') AS normalized_street_name
    FROM 
        customer_address
),
Customer_Analysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_dep_count) AS avg_dependent_count,
        STRING_AGG(cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Item_Analysis AS (
    SELECT 
        i_brand,
        COUNT(*) AS item_count,
        SUM(i_current_price) AS total_price,
        STRING_AGG(DISTINCT i_category, ', ') AS categories
    FROM 
        item
    GROUP BY 
        i_brand
),
Sales_Analysis AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_city,
    a.uppercase_street_name,
    a.street_name_length,
    a.normalized_street_name,
    c.cd_gender,
    c.customer_count,
    c.avg_dependent_count,
    c.education_levels,
    i.i_brand,
    i.item_count,
    i.total_price,
    i.categories,
    s.total_sales,
    s.total_revenue
FROM 
    Address_Analysis a
JOIN 
    Customer_Analysis c ON c.customer_count > 0
JOIN 
    Item_Analysis i ON i.item_count > 0
JOIN 
    Sales_Analysis s ON s.total_sales > 0
ORDER BY 
    a.ca_city, c.cd_gender, i.i_brand;
