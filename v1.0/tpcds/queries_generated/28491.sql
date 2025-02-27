
WITH Address_Concat AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country) AS full_address
    FROM 
        customer_address
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        ca.full_address
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Address_Concat ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Sales_Info AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
Date_Analysis AS (
    SELECT 
        d.d_date,
        DENSE_RANK() OVER (ORDER BY d.d_date) AS date_rank
    FROM 
        date_dim d 
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.full_address,
    da.d_date,
    da.date_rank,
    si.total_sales_quantity,
    si.total_sales_amount
FROM 
    Customer_Info ci
JOIN 
    Sales_Info si ON ci.c_customer_sk = si.ws_bill_customer_sk
JOIN 
    Date_Analysis da ON si.ws_sold_date_sk = da.d_date_sk
ORDER BY 
    da.date_rank, ci.customer_name;
