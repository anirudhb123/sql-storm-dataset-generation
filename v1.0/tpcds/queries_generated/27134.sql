
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY')
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        ss.total_sales,
        ss.order_count
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.ca_city,
    c.ca_state,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count
FROM 
    CustomerDetails AS c
LEFT JOIN 
    SalesSummary AS s ON c.c_customer_id = s.ws_bill_customer_sk
ORDER BY 
    total_sales DESC, full_name;
