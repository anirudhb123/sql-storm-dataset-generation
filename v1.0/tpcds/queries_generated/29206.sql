
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER(PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_discount_amt,
        ws.ws_net_paid,
        d.d_date AS sale_date,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year = 2023
), 
CustomerSales AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        SUM(sd.ws_net_paid) AS total_spent,
        COUNT(sd.ws_order_number) AS total_orders
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_order_number
    GROUP BY 
        ci.c_customer_id, ci.c_first_name, ci.c_last_name
    HAVING 
        SUM(sd.ws_net_paid) > 500
)

SELECT 
    c.c_first_name || ' ' || c.c_last_name AS CustomerName,
    c.total_orders,
    c.total_spent,
    ci.ca_city,
    ci.ca_state
FROM 
    CustomerSales c
JOIN 
    CustomerInfo ci ON c.c_customer_id = ci.c_customer_id
ORDER BY 
    c.total_spent DESC
LIMIT 10;
