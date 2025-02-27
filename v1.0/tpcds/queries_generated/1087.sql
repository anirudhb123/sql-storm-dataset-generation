
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ca.ca_city,
    SUM(sd.total_quantity) AS city_total_quantity,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    COALESCE(MAX(sd.total_sales), 0) AS max_sales
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_order_number
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA' AND 
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
GROUP BY 
    ca.ca_city
HAVING 
    SUM(sd.total_quantity) > 100
ORDER BY 
    city_total_quantity DESC;
