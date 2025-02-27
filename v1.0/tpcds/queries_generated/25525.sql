
WITH CustomerDetails AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        d.d_date,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),
SalesByCustomer AS (
    SELECT 
        c.full_name,
        c.c_email_address,
        SUM(s.ws_net_profit) AS total_profit,
        COUNT(s.ws_order_number) AS total_orders
    FROM 
        CustomerDetails c
    JOIN 
        SalesInfo s ON c.c_email_address = s.ws_bill_customer_sk
    GROUP BY 
        c.full_name, c.c_email_address
    HAVING 
        total_profit > 1000
)
SELECT 
    full_name,
    c_email_address,
    total_profit,
    total_orders
FROM 
    SalesByCustomer
ORDER BY 
    total_profit DESC
LIMIT 10;
