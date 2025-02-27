
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        REPLACE(REPLACE(c.c_email_address, '@', ' at '), '.', ' dot ') AS email_formatted,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
),
DateFormatted AS (
    SELECT 
        d.d_date_sk, 
        TO_CHAR(d.d_date, 'YYYY-MM-DD') AS formatted_date
    FROM 
        date_dim d
)
SELECT 
    ci.full_name, 
    ci.email_formatted, 
    ci.ca_city, 
    ci.ca_state, 
    df.formatted_date, 
    COALESCE(sd.total_sales, 0) AS total_sales, 
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_ship_date_sk
JOIN 
    DateFormatted df ON sd.ws_ship_date_sk = df.d_date_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC;
