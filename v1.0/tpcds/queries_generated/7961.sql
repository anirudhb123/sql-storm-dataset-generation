
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
), 
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    ORDER BY 
        cs.total_sales DESC 
    LIMIT 10
),
SalesDetails AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023
        ) AND (
            SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023
        )
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    sd.total_quantity,
    sd.total_orders,
    sd.avg_order_value,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ib.ib_income_band_sk
FROM 
    TopCustomers tc
JOIN 
    SalesDetails sd ON tc.c_customer_id = sd.c_customer_id
JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
JOIN 
    household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    tc.total_sales > 1000
ORDER BY 
    tc.total_sales DESC;
