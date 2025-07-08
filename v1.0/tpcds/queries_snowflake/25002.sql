
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        LISTAGG(DISTINCT ca.ca_city, ', ') WITHIN GROUP (ORDER BY ca.ca_city) AS cities,
        LISTAGG(DISTINCT ca.ca_state, ', ') WITHIN GROUP (ORDER BY ca.ca_state) AS states
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
), 
SalesDetails AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders,
    cd.cities,
    cd.states
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesDetails sd ON cd.c_customer_id = CAST(sd.ws_bill_customer_sk AS STRING)
ORDER BY 
    cd.cd_purchase_estimate DESC, total_sales DESC
LIMIT 100;
