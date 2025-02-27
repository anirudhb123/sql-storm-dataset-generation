
WITH FilteredCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
        AND d.d_year BETWEEN 2020 AND 2022
),
AggCustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        FilteredCustomers c ON ws.ws_bill_customer_sk = c.c_customer_id
    GROUP BY 
        c.c_customer_id
),
FinalResults AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.ca_city,
        c.ca_state,
        s.total_orders,
        s.total_spent
    FROM 
        FilteredCustomers c
    JOIN 
        AggCustomerSales s ON c.c_customer_id = s.c_customer_id
)
SELECT 
    FIRST_VALUE(f.c_first_name) OVER (PARTITION BY f.ca_city ORDER BY f.total_spent DESC) AS top_spender_first_name,
    FIRST_VALUE(f.c_last_name) OVER (PARTITION BY f.ca_city ORDER BY f.total_spent DESC) AS top_spender_last_name,
    f.ca_city,
    f.total_orders,
    f.total_spent
FROM 
    FinalResults f
ORDER BY 
    f.ca_city, f.total_spent DESC;
