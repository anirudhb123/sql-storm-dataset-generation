
WITH SalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2023-01-01'
),
TopCustomers AS (
    SELECT 
        c_customer_sk,
        SUM(ws_sales_price * ws_quantity) AS total_spent
    FROM 
        SalesData
    WHERE 
        order_rank <= 5
    GROUP BY 
        c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_marital_status = 'M'
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cdem.cd_gender,
    cdem.cd_marital_status,
    cab.ca_city,
    cab.ca_state,
    tc.total_spent
FROM 
    TopCustomers tc
JOIN 
    customer cu ON tc.c_customer_sk = cu.c_customer_sk
JOIN 
    CustomerDemographics cdem ON cu.c_current_cdemo_sk = cdem.cd_demo_sk
LEFT JOIN 
    CustomerAddress cab ON cu.c_current_addr_sk = cab.ca_address_sk
WHERE 
    tc.total_spent > (SELECT AVG(total_spent) FROM TopCustomers)
ORDER BY 
    tc.total_spent DESC;
