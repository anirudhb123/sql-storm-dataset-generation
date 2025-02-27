
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        REPLACE(c.c_email_address, '@', '[at]') AS modified_email,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        CASE 
            WHEN c.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
            WHEN c.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
            WHEN c.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS birth_quarter
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
ReturnData AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number
)
SELECT 
    ci.full_name,
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(sd.total_quantity) AS total_items_sold,
    SUM(sd.total_sales) AS total_sales_amount,
    COALESCE(SUM(rd.total_return_quantity), 0) AS total_items_returned,
    COALESCE(SUM(rd.total_return_amount), 0) AS total_return_amount,
    CASE 
        WHEN SUM(sd.total_sales) - COALESCE(SUM(rd.total_return_amount), 0) < 0 THEN 'Negative Profit'
        ELSE 'Profit'
    END AS profit_status,
    ci.birth_quarter
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_id = sd.ws_order_number
LEFT JOIN 
    ReturnData rd ON sd.ws_order_number = rd.wr_order_number
GROUP BY 
    ci.full_name, ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.birth_quarter
ORDER BY 
    total_sales_amount DESC;
