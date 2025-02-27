
WITH Address_Details AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        LENGTH(ca.ca_street_name) AS street_name_length
    FROM 
        customer_address ca
), 
Customer_Segment AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
Date_Summary AS (
    SELECT 
        d.d_year,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    ad.full_address,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    ds.d_year,
    ds.total_orders,
    ds.total_sales
FROM 
    Address_Details ad
JOIN 
    Customer_Segment cs ON cs.customer_count > 0
JOIN 
    Date_Summary ds ON ds.total_orders > 0
WHERE 
    ad.street_name_length > 10
ORDER BY 
    ds.total_sales DESC, cs.customer_count DESC;
