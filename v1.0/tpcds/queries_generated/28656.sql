
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite: ', ca_suite_number) ELSE '' END) AS Full_Address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS Full_Name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS Total_Profit,
        COUNT(ws_order_number) AS Total_Orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedDetails AS (
    SELECT 
        c.Full_Name,
        a.Full_Address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        COALESCE(sd.Total_Profit, 0) AS Total_Profit,
        COALESCE(sd.Total_Orders, 0) AS Total_Orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        AddressDetails a
    JOIN 
        CustomerDetails cd ON a.ca_address_sk = cd.c_customer_sk
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    Full_Name,
    Full_Address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    Total_Profit,
    Total_Orders,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate
FROM 
    CombinedDetails
ORDER BY 
    Total_Profit DESC
LIMIT 100;
