
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_email_address, 
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
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_email_address, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate
    FROM 
        CustomerData c
    WHERE 
        c.rnk <= 10
), 
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_bill_customer_sk
) 
SELECT 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.c_email_address, 
    tc.cd_gender, 
    tc.cd_marital_status, 
    SUM(sd.total_net_profit) AS total_profit
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.c_email_address, 
    tc.cd_gender, 
    tc.cd_marital_status
ORDER BY 
    total_profit DESC;
