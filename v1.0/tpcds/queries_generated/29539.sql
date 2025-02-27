
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS birth_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_birth_year = d.d_year AND c.c_birth_month = d.d_month_seq AND c.c_birth_day = d.d_dom
),
WebSalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        wss.total_orders,
        wss.total_sales,
        wss.last_order_date
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        WebSalesSummary wss ON ci.c_customer_id = wss.ws_bill_customer_sk
    WHERE 
        ci.cd_gender = 'F' AND
        ci.cd_marital_status = 'M' AND
        wss.total_sales > 1000
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    ca_city, 
    ca_state,
    total_orders, 
    total_sales, 
    last_order_date
FROM 
    FinalReport
ORDER BY 
    total_sales DESC;
