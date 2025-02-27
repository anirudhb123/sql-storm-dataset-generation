
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MIN(ws_sold_date_sk) AS first_purchase_date,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ss.total_sales,
        ss.order_count,
        ss.first_purchase_date,
        ss.last_purchase_date
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    order_count,
    first_purchase_date,
    last_purchase_date
FROM 
    FinalReport
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
