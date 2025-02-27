
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateInfo AS (
    SELECT 
        d.d_date_id,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_current_year = 'Y'
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.full_name,
        ci.cd_gender,
        di.d_date,
        di.d_day_name,
        di.d_month_seq,
        ci.ca_city,
        ci.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    JOIN 
        DateInfo di ON ws.ws_sold_date_sk = di.d_date_id
),
AggregatedSales AS (
    SELECT 
        full_name,
        cd_gender,
        ca_city,
        ca_state,
        SUM(ws_sales_price) AS total_amount,
        COUNT(ws_order_number) AS total_orders,
        MIN(d_date) AS first_order_date,
        MAX(d_date) AS last_order_date,
        COUNT(DISTINCT d_day_name) AS active_days
    FROM 
        SalesData
    GROUP BY 
        full_name, cd_gender, ca_city, ca_state
)
SELECT 
    total_orders,
    total_amount,
    active_days,
    cd_gender,
    ca_city,
    ca_state,
    ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS rank
FROM 
    AggregatedSales
WHERE 
    total_orders > 0
ORDER BY 
    total_amount DESC
LIMIT 100;
