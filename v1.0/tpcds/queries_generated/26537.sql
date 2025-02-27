
WITH AddressInfo AS (
    SELECT 
        CA.ca_address_id,
        CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type) AS Full_Street_Address,
        CA.ca_city,
        CA.ca_state,
        CA.ca_zip,
        CA.ca_country
    FROM 
        customer_address CA
),
CustomerDetails AS (
    SELECT 
        C.c_customer_id,
        CONCAT(C.c_salutation, ' ', C.c_first_name, ' ', C.c_last_name) AS Full_Customer_Name,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status
    FROM 
        customer C
    JOIN 
        customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        WS.ws_order_number,
        WS.ws_quantity,
        SUM(WS.ws_sales_price) AS Total_Sales_Amount,
        D.d_date AS Sale_Date
    FROM 
        web_sales WS
    JOIN 
        date_dim D ON WS.ws_sold_date_sk = D.d_date_sk
    GROUP BY 
        WS.ws_order_number, WS.ws_quantity, D.d_date
)
SELECT 
    C.c_customer_id,
    C.Full_Customer_Name,
    A.Full_Street_Address,
    A.ca_city,
    A.ca_state,
    A.ca_zip,
    A.ca_country,
    S.ws_order_number,
    S.Total_Sales_Amount,
    S.Sale_Date
FROM 
    CustomerDetails C
JOIN 
    AddressInfo A ON C.c_customer_id = A.ca_address_id
JOIN 
    SalesInfo S ON S.ws_order_number IN (SELECT WS.ws_order_number FROM web_sales WS WHERE WS.ws_bill_customer_sk = C.c_customer_sk)
WHERE 
    A.ca_state = 'CA' AND 
    S.Total_Sales_Amount > 100
ORDER BY 
    S.Sale_Date DESC, 
    C.Full_Customer_Name;
