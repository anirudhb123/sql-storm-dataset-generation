
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressData AS ad ON c.c_current_addr_sk = ad.ca_address_sk
),
PurchaseData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
RankedCustomers AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        COALESCE(pd.total_sales, 0) AS total_sales,
        COALESCE(pd.order_count, 0) AS order_count,
        ROW_NUMBER() OVER (ORDER BY COALESCE(pd.total_sales, 0) DESC) AS sales_rank
    FROM 
        CustomerData AS cd
    LEFT JOIN 
        PurchaseData AS pd ON cd.c_customer_sk = pd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    total_sales,
    order_count,
    full_address
FROM 
    RankedCustomers
WHERE 
    sales_rank <= 10
ORDER BY 
    total_sales DESC;
