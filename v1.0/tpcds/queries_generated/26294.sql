
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), AddressDetails AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
), DateDetails AS (
    SELECT 
        d.d_date,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023
), WebSalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        DateDetails dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.purchase_estimate_band,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    ad.full_address,
    ws.total_quantity,
    ws.total_sales
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_id = ad.c_customer_id
LEFT JOIN 
    WebSalesDetails ws ON cd.c_customer_id = ws.ws_item_sk
ORDER BY 
    ws.total_sales DESC, cd.c_last_name;
