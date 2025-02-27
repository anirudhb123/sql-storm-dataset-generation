
WITH Address_Stats AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city
), 
Customer_Gender_Dist AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
), 
Sales_Stats AS (
    SELECT 
        WS.ws_web_site_id,
        SUM(WS.ws_sales_price) AS total_sales,
        SUM(WS.ws_quantity) AS total_quantity,
        COUNT(DISTINCT WS.ws_order_number) AS total_orders
    FROM 
        web_sales WS
    GROUP BY 
        WS.ws_web_site_id
)
SELECT 
    A.ca_city,
    A.address_count,
    A.full_address_list,
    G.cd_gender,
    G.customer_count,
    S.ws_web_site_id,
    S.total_sales,
    S.total_quantity,
    S.total_orders
FROM 
    Address_Stats A
CROSS JOIN 
    Customer_Gender_Dist G
CROSS JOIN 
    Sales_Stats S
WHERE 
    A.address_count > 10 
    AND G.customer_count > 50 
    AND S.total_sales > 1000
ORDER BY 
    A.ca_city, G.cd_gender, S.total_sales DESC;
