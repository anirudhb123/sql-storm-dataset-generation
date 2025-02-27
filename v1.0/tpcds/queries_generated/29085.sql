
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT s.s_store_sk) AS total_stores
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store s ON c.c_customer_sk = s.s_store_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
ReturnData AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_item_sk) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_discount, 0) AS total_discount,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(rd.total_returns, 0) AS total_returns,
    ci.total_stores
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
LEFT JOIN 
    ReturnData rd ON ci.c_customer_sk = rd.sr_customer_sk
ORDER BY 
    total_sales DESC;
