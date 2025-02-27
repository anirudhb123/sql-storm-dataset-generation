
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopPurchasers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rnk <= 10
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(*) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tp.c_customer_sk,
    tp.c_first_name,
    tp.c_last_name,
    tp.cd_gender,
    tp.cd_marital_status,
    tp.cd_education_status,
    tp.cd_purchase_estimate,
    addr.ca_address_id,
    addr.ca_city,
    addr.ca_state,
    sales.total_spent,
    sales.total_orders
FROM 
    TopPurchasers tp
LEFT JOIN 
    AddressDetails addr ON addr.ca_address_id = (
        SELECT ca.ca_address_id 
        FROM customer_address ca 
        WHERE ca.ca_address_sk = tp.c_customer_sk
        LIMIT 1
    )
LEFT JOIN 
    SalesSummary sales ON sales.ws_bill_customer_sk = tp.c_customer_sk
WHERE 
    tp.cd_gender = 'F'
ORDER BY 
    tp.cd_purchase_estimate DESC, tp.c_last_name ASC;
