
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
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
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateDetails AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_quarter_seq,
        d.d_year
    FROM 
        date_dim d
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ca.ca_country,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
)

SELECT 
    addr.full_address,
    addr.ca_city,
    addr.ca_state,
    addr.ca_zip,
    addr.ca_country,
    COUNT(DISTINCT cust.c_customer_sk) AS total_customers,
    SUM(sales.ws_quantity) AS total_quantity_sold,
    SUM(sales.ws_ext_sales_price) AS total_sales,
    SUM(sales.ws_net_profit) AS total_net_profit,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_seq
FROM 
    AddressParts addr
JOIN 
    CustomerDetails cust ON addr.ca_city = cust.c_city
JOIN 
    SalesDetails sales ON addr.ca_country = sales.ca_country AND addr.ca_state = sales.ca_state
JOIN 
    DateDetails d ON sales.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    addr.full_address, 
    addr.ca_city, 
    addr.ca_state, 
    addr.ca_zip, 
    addr.ca_country, 
    d.d_year, 
    d.d_month_seq, 
    d.d_quarter_seq
ORDER BY 
    total_sales DESC, 
    total_customers DESC;
