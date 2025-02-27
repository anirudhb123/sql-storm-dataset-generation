
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY')
),
CustomerDetails AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        c_email_address
    FROM 
        customer
    WHERE 
        c_preferred_cust_flag = 'Y'
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.customer_name,
    cd.c_email_address,
    wd.full_address,
    ws.total_sales,
    ws.order_count
FROM 
    CustomerDetails cd
JOIN 
    WebSalesSummary ws ON ws.ws_bill_customer_sk = cd.c_customer_sk
JOIN 
    AddressDetails wd ON wd.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = ws.ws_bill_customer_sk)
WHERE 
    ws.total_sales > 500
ORDER BY 
    ws.total_sales DESC
LIMIT 100;
