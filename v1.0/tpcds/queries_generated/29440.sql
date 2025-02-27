
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cad.ca_city, 
        cad.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        UPPER(c.c_email_address) AS email_uppercase
    FROM 
        customer AS c
    JOIN 
        customer_address AS cad ON c.c_current_addr_sk = cad.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cad.ca_state IN ('NY', 'CA') 
        AND cd.cd_gender = 'F'
), SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
), CustomerSales AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_spent
    FROM 
        CustomerDetails AS cd
    LEFT JOIN 
        SalesData AS sd ON cd.c_customer_id = sd.ws_order_number
    GROUP BY 
        cd.c_customer_id, cd.full_name
)
SELECT 
    *
FROM 
    CustomerSales
WHERE 
    total_quantity > 10
ORDER BY 
    total_spent DESC;
