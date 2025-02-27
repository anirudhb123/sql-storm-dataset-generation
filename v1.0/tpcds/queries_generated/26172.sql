
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DATE(d.d_date) AS order_date,
        CONCAT(ws.ws_bill_addr_sk, '-', ws.ws_ship_addr_sk) AS address_key
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
AggregatedSales AS (
    SELECT 
        cd.full_name,
        SUM(sd.ws_sales_price) AS total_spent,
        COUNT(sd.ws_order_number) AS order_count
    FROM 
        CustomerDetails cd
    JOIN 
        SalesDetails sd ON cd.c_customer_id = sd.ws_bill_customer_sk
    GROUP BY 
        cd.full_name
)
SELECT 
    full_name,
    total_spent,
    order_count,
    CASE 
        WHEN total_spent > 1000 THEN 'High Spender'
        WHEN total_spent > 500 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    AggregatedSales
ORDER BY 
    total_spent DESC;
