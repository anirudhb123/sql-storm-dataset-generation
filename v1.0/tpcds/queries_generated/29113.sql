
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) AS street_number,
        TRIM(ca_street_name) AS street_name,
        TRIM(ca_street_type) AS street_type,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM 
        customer_address
),
CustomerIdentifiers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        COALESCE(d.cd_gender, 'N/A') AS gender,
        TRIM(c.c_email_address) AS email,
        TRIM(ca.street_number) AS street_number,
        TRIM(ca.street_name) AS street_name,
        TRIM(ca.city) AS city,
        TRIM(ca.state) AS state
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressComponents ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DailySales AS (
    SELECT 
        d.d_date_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date_id
)
SELECT 
    ci.full_name,
    ci.gender,
    ci.email,
    ci.street_number,
    ci.street_name,
    ci.city,
    ci.state,
    ds.d_date_id,
    ds.total_quantity,
    ds.total_sales
FROM 
    CustomerIdentifiers ci
JOIN 
    DailySales ds ON ds.total_quantity > 0
ORDER BY 
    ds.total_sales DESC, ci.full_name;
