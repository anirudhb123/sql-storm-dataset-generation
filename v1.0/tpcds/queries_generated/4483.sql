
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 

SalesStats AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, 
        ws.ws_item_sk
)

SELECT 
    ci.c_customer_id,
    ci.ca_city,
    ci.ca_state,
    ss.total_quantity_sold,
    ss.total_sales
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesStats ss ON ci.c_customer_sk = ss.ws_ship_customer_sk
WHERE 
    ci.purchase_rank <= 10 
    AND (ci.cd_marital_status = 'M' OR ci.cd_education_status LIKE '%Graduate%')
    AND ss.total_sales IS NOT NULL
ORDER BY 
    ss.total_sales DESC;
