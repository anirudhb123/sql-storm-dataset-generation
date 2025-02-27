
WITH RankedCustomer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressWithDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
),
DateDetails AS (
    SELECT 
        d.d_date_sk,
        TO_CHAR(d.d_date, 'Month DD, YYYY') AS formatted_date,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    rc.customer_full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    dd.formatted_date,
    sd.total_sales_amount,
    sd.order_count
FROM 
    RankedCustomer rc
JOIN 
    AddressWithDetails ad ON rc.c_customer_sk = ad.ca_address_sk
JOIN 
    DateDetails dd ON dd.d_date_sk = rc.c_customer_sk  -- Simulating a relation for demonstration
JOIN 
    SalesData sd ON sd.ws_item_sk = rc.c_customer_sk  -- Simulating a relation for demonstration
WHERE 
    rc.gender_rank <= 5
ORDER BY 
    ad.ca_city, sd.total_sales_amount DESC;
