
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateInfo AS (
    SELECT 
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        d.d_current_year
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023
),
ShipModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_type
    FROM 
        ship_mode sm
    WHERE 
        sm.sm_carrier LIKE '%express%'
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
ProfileMetrics AS (
    SELECT 
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(email_length) AS total_email_length,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_customers,
        COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_customers,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS average_sales_price,
        STRING_AGG(DISTINCT sm.sm_type, ', ') AS used_ship_modes
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
    JOIN 
        ShipModes sm ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
)
SELECT 
    *,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM 
    ProfileMetrics;
