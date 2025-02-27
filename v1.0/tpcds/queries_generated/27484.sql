
WITH Address_Summary AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_street_names,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_street_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Customer_Gender AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
Sales_Analysis AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    AS.city AS address_city,
    AS.address_count,
    AS.unique_street_names,
    CG.cd_gender,
    CG.customer_count,
    SA.d_year AS sales_year,
    SA.total_sales,
    SA.order_count
FROM 
    Address_Summary AS AS
LEFT JOIN 
    Customer_Gender AS CG ON true
LEFT JOIN 
    Sales_Analysis AS SA ON true
ORDER BY 
    AS.city, CG.cd_gender, SA.d_year;
