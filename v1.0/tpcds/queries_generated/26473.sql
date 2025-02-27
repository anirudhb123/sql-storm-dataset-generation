
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        LENGTH(c.c_email_address) AS email_length,
        COALESCE(NULLIF(UPPER(c.c_first_name), ''), 'NONE') AS non_empty_first_name
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DATE(DATE_ADD(d.d_date, INTERVAL ws.ws_sold_date_sk DAY)) AS sale_date,
        C.city_count,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_order_number) AS total_sales
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        (SELECT 
            COUNT(DISTINCT ca.ca_city) AS city_count 
         FROM 
            customer_address AS ca) AS C ON 1=1
    WHERE 
        ws.ws_sales_price > 0
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    si.sale_date,
    si.ws_order_number,
    si.total_sales,
    SUM(si.ws_quantity) OVER (PARTITION BY ci.c_customer_id ORDER BY si.sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity,
    AVG(si.ws_sales_price) OVER (PARTITION BY ci.c_customer_id) AS avg_sales_price,
    COUNT(si.ws_order_number) OVER (PARTITION BY ci.c_customer_id) AS order_count
FROM 
    CustomerInfo AS ci
JOIN 
    SalesInfo AS si ON ci.c_customer_id = si.ws_order_number
ORDER BY 
    ci.full_name, si.sale_date;
