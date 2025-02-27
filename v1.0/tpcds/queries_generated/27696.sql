
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_birth_country
    FROM 
        customer
),
WebSalesDetails AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ship_date_sk,
        ws_net_paid
    FROM 
        web_sales
),
DateDetails AS (
    SELECT 
        d_date_sk,
        TO_CHAR(d_date, 'Month YYYY') AS sales_month,
        d_year
    FROM 
        date_dim
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.c_birth_country,
    dd.sales_month,
    dd.d_year,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_sales
FROM 
    WebSalesDetails ws
JOIN 
    AddressDetails ad ON ws.ws_ship_addr_sk = ad.ca_address_sk
JOIN 
    CustomerDetails cd ON ws.ws_ship_customer_sk = cd.c_customer_sk
JOIN 
    DateDetails dd ON ws.ws_sold_date_sk = dd.d_date_sk
GROUP BY 
    ad.full_address, cd.full_name, cd.c_birth_country, dd.sales_month, dd.d_year
ORDER BY 
    dd.d_year DESC, total_sales DESC;
