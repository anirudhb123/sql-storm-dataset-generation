
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_street_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_street_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS diverse_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    ds.d_date,
    ds.total_sales,
    ds.total_orders,
    ds.diverse_customers
FROM 
    CustomerInfo cs
LEFT JOIN 
    DailySales ds ON ds.d_date = (
        SELECT 
            MAX(d.d_date)
        FROM 
            DailySales d
        WHERE 
            d.total_sales > cs.cd_purchase_estimate
    )
WHERE 
    cs.cd_gender = 'F'
ORDER BY 
    ds.total_sales DESC;
